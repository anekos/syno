
require 'curb'
require 'json'
require 'uri'



class API
  BASE = "http://#{Config.host}:#{Config.port}/webapi"

  def initialize(name: nil, cgi: nil, api:, version: 2, method: nil, exit_if_failed: true)
    @exit_if_failed = exit_if_failed

    url = if name
      "#{BASE}/#{name}/#{cgi}.cgi"
    else
      "#{BASE}/#{cgi}.cgi"
    end

    params = {:version => version, :method => method, :api => api}.map {|k, v| "#{k}=#{v}" } .join('&')

    @url = URI.parse(url + '?' + params)
  end

  def get(params = {})
    response = Curl.get(@url.to_s, params) do |res|
      res.enable_cookies = true
      res.cookiefile = 'cookies'
      res.cookiejar = 'cookies'
    end
    JSON.parse(response.body_str).tap do
      |result|
      raise 'API Failed' unless result['success']
    end
  end
end

