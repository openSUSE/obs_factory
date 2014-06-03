module ObsFactory
  class StagingProjectPresenter < BasePresenter
    def openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(model.openqa_jobs)
    end

    def subprojects
      ObsFactory::StagingProjectPresenter.wrap(model.subprojects)
    end

    def description_packages
      packages = YAML.load(description)["requests"].map {|i| i["package"] }
      packages.sort.join(', ')
    end
  end
end
