module ObsFactory
  class StagingProjectPresenter < BasePresenter
    def openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(model.openqa_jobs)
    end

    def subprojects
      ObsFactory::StagingProjectPresenter.wrap(model.subprojects)
    end
  end
end
