module ObsFactory
  # View decorator for StagingProject
  class StagingProjectPresenter < BasePresenter

    # Wraps the associated openqa_jobs with the corresponding decorator.
    #
    # @return [Array] Array of OpenqaJobPresenter objects
    def openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(model.openqa_jobs)
    end

    # Wraps the associated subprojects with the corresponding decorator.
    #
    # @return [Array] Array of StagingProjectPresenter objects
    def subprojects
      ObsFactory::StagingProjectPresenter.wrap(model.subprojects)
    end

    # List of packages included in the staging_project.
    #
    # The names are extracted from the description (that is in fact a yaml
    # string).
    #
    # @return [String] package names delimited by commas
    def description_packages
      packages = YAML.load(description)["requests"].map {|i| i["package"] }
      packages.sort.join(', ')
    end
  end
end
