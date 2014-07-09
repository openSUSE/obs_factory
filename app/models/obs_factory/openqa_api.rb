require 'net/http'

# Commodity class to encapsulate calls to the openQA API.
module ObsFactory
  class OpenqaApi

    def initialize(base_url)
      @base_url = base_url.chomp('/') + '/api/v1/'
    end

    # A get that follows redirects - openqa redirects to https
    def _get(uri)
      req_path = uri.path
      req_path << "?" + uri.query unless uri.query.empty?
      req = Net::HTTP::Get.new(req_path)
      resp = Net::HTTP.start(uri.host, use_ssl: uri.scheme == "https") { |http| http.request(req) }
      if resp.code.to_i == 302 or resp.code.to_i == 301
        Rails.logger.debug "following to #{resp.header['location']}"
        return _get(URI.parse(resp.header['location']))
      end
      return resp
    end

    # Performs a GET query on the openQA API
    #
    # @param [String] url     action to call
    # @param [Hash]   params  query parameters
    # @param [Hash]   options  additional options. Right now :base_url to
    #                   overwrite the default one
    # @return [Object]  the response decoded (usually a Hash)
    def get(url, params = {}, options = {})
      if options[:base_url]
        uri = URI.join(options[:base_url].chomp('/')+'/', url)
      else
        uri = URI.join(@base_url, url)
      end
      uri.query = params.to_query
      resp = _get(uri)
      raise "OpenQA API GET failure: \"#{url}\" with \"#{params.to_query}\"" unless resp.code.to_i == 200
      ActiveSupport::JSON.decode(resp.body)
    end
  end
end
