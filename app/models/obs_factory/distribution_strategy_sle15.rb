module ObsFactory

  class DistributionStrategySLE15 < DistributionStrategyFactory

    def staging_manager
      'sle-staging-managers'
    end

    def repo_url
      'http://download.opensuse.org/distribution/13.2/repo/oss/media.1/build'
    end

    def openqa_version
      "SLES 15"
    end

    # Name of the ISO file by the given staging project tracked on openqa
    #
    # @return [String] file name
    def openqa_iso(project)
      ending = project_iso(project)
      "SLE15-Staging:#{project.letter}-#{ending}"
    end

  end
end
