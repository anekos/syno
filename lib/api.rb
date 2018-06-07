
require 'curb'
require 'json'
require 'uri'



class API
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

  private def request(method, params = {})
    response =
      case method
      when :post
        Curl.post(@url.to_s, @basic.merge(params)) do |curl|
          setup_curl(curl)
          curl.headers['X-SYNO-TOKEN'] = @token if @token
        end
      when :get
        basic = @basic.map {|k, v| "#{k}=#{v}" } .join('&')
        Curl.get(@url.to_s + '?' + basic, params) {|curl| setup_curl(curl)}
      end

    JSON.parse(response.body_str).tap do
      |result|
      raise "API Failed: #{result}" unless result['success']
    end
  end

  private def setup_curl(curl)
    curl.enable_cookies = true
    curl.cookiefile = 'cookies'
    curl.cookiejar = 'cookies'
  end
end

