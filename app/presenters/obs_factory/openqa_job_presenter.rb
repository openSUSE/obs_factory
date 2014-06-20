module ObsFactory
  # View decorator for OpenqaJob
  class OpenqaJobPresenter < BasePresenter
    # URL of the job in the openQA instance
    #
    # @return [String] the full URL
    def url
      OpenqaJob.openqa_base_url.chomp('/') + "/tests/#{id}"
    end
  end
end
