module ObsFactory
  class OpenqaJobPresenter < BasePresenter
    def url
      OpenqaJob.openqa_base_url.chomp('/') + "/tests/#{id}"
    end
  end
end
