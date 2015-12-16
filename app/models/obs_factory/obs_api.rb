require 'net/https'
require 'xmlhash'

module ObsFactory
  class ObsApi

    def initialize
      if use_api?
        @@api_url = OBS_CONFIG["obs_api"]
        @@user    = OBS_CONFIG["obs_user"]
        @@pass    = OBS_CONFIG["obs_pass"]
      end
    end

    def use_api?
      return OBS_CONFIG["external_obs"]
    end

    def _get(uri)
      req_path = uri.path
      req_path << "?" + uri.query
      req = Net::HTTP::Get.new(req_path)
      req.basic_auth(@@user, @@pass)
      resp = Net::HTTP.start(uri.host,:use_ssl => uri.scheme == 'https') { |http| http.request(req) }
      return Xmlhash.parse(resp.body)
    end

    def geturl(project,params = {})
        uri = URI.join(@@api_url.chomp('/') + '/' + "build" + '/'  + project + '/' + "_result")
        uri.query = params.to_query
        uri.query = uri.query.gsub(/%5B%5D/,"")
        return _get(uri)
    end
    def direct(project, url, arg)
        params = {}
        uri = URI.join(@@api_url.chomp('/') + '/' + url + '/' + project + '/' + arg)
        uri.query = params.to_query
        return _get(uri)
    end
  end
end
