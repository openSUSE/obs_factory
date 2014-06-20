require 'net/http'

# Commodity class to encapsulate calls to the openQA API.
module ObsFactory
  class OpenqaApi

    def initialize(base_url)
      @base_url = base_url.chomp('/') + '/api/v1/'
    end

    # Performs a GET query on the openQA API
    #
    # @param [String] url     action to call
    # @param [Hash]   params  query parameters
    # @return [Object]  the response decoded (usually a Hash)
    def get(url, params = {})
      uri = URI.join(@base_url, url)
      req_path = uri.path
      req_path << "?" + params.to_query unless params.empty?
      req = Net::HTTP::Get.new(req_path)
      resp = Net::HTTP.start(uri.host, use_ssl: uri.scheme == "https") { |http| http.request(req) }
      raise "OpenQA API GET failure: \"#{url}\" with \"#{params.to_query}\"" unless resp.code.to_i == 200
      ActiveSupport::JSON.decode(resp.body)
    end
  end
end
