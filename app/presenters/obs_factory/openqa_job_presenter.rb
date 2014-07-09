module ObsFactory
  # View decorator for OpenqaJob
  class OpenqaJobPresenter < BasePresenter
    # URL of the job in the openQA instance
    #
    # @return [String] the full URL
    def url
      OpenqaJob.openqa_base_url.chomp('/') + "/tests/#{id}"
    end

    # The part of the name that refers to the testsuite
    #
    # @return [String] type of test
    def test
      name.split('-').last
    end
  end
end
