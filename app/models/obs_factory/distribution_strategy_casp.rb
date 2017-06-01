module ObsFactory

  class DistributionStrategyCasp < DistributionStrategyFactory

    def casp_version
      match = project.name.match(/^SUSE:SLE-12-SP.*CASP(\d*)/ )
      match[1]
    end


    def repo_url
      'http://download.opensuse.org/distribution/13.2/repo/oss/media.1/build'
    end

    def openqa_version
      '1.0'
    end

    # Name of the ISO file by the given staging project tracked on openqa
    #
    # @return [String] file name
    def openqa_iso(project)
      project_iso(project)
    end

  end
end
