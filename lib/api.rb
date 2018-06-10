
require 'curb'
require 'json'
require 'uri'



class Session < Struct.new(:token)
  def to_yaml
    {:token => self.token}.to_yaml
  end

  def self.from_yaml (yaml)
    self.new(yaml[:token])
  end
end

class API
  @@relogined = false
  @@session = nil

  BASE = "http://#{Config.host}:#{Config.port}/webapi"

  def initialize(name: nil, cgi: nil, api:, version: 2, method: nil, token: nil, exit_if_failed: true)
    @exit_if_failed = exit_if_failed

    url = if name
      "#{BASE}/#{name}/#{cgi}.cgi"
    else
      "#{BASE}/#{cgi}.cgi"
    end

    @token = token
    @basic = {:version => version, :method => method, :api => api}
    @url = URI.parse(url)
  end

  def get(params = {})
    request(:get, params)
  end

  def post(params = {})
    request(:post, params)
  end

  def self.login(relogin: false)
    if !relogin && Path.last.file?
      @@session = Session.from_yaml(YAML.load(File.read(Path.last)))
      return
    end

    result = API.new(
      cgi: 'auth',
      api: 'SYNO.API.Auth',
      method: 'login'
    ).get(
      :account => Config.account,
      :passwd => Config.password,
      :session => 'AudioStation',
      :format => 'cookie',
      :enable_syno_token => 'yes',
    )

    if token = result && result['success'] && result.dig('data', 'synotoken')
      @@session = Session.new(token).tap do
        |it|
        Path.last.parent.mkpath
        File.write(Path.last, it.to_yaml)
      end
    end
  end

  def self.logout
    API.new(
      cgi: 'auth',
      api: 'SYNO.API.Auth',
      method: 'logout'
    ).get(
      :account => Config.account,
      :session => 'AudioStation'
    )
  end

  private def request(method, params = {})
    response =
      case method
      when :post
        Curl.post(@url.to_s, @basic.merge(params)) do |curl|
          setup_curl(curl)
          curl.headers['X-SYNO-TOKEN'] = @@session.token if @token
        end
      when :get
        params[:SynoToken] = @@session.token if @token
        basic = @basic.map {|k, v| "#{k}=#{v}" } .join('&')
        Curl.get(@url.to_s + '?' + basic, params) {|curl| setup_curl(curl)}
      end

    JSON.parse(response.body_str).tap do
      |result|
      unless result['success']
        unless @@relogined
          @@relogined = true
          API.login(relogin: true)
          return request(method, params)
        end
        raise "API Failed: #{result}"
      end
    end
  end

  private def setup_curl(curl)
    curl.enable_cookies = true
    curl.cookiefile = Path.cookie.to_s
    curl.cookiejar = Path.cookie.to_s
  end
end

