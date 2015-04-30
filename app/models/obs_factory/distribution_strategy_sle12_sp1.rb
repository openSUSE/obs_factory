module ObsFactory

  class DistributionStrategySLE12SP1 < DistributionStrategyFactory

    # If the distribution is tested somewhere else than openqa.opensuse.org
    # it needs to overwrite this
    #
    # @return [String] URL of openQA instance
    def openqa_base_url
      # build.opensuse.org can reach only the host directly, so we need
      # to use http - and accept a https redirect if used on work stations
      "http://openqa.suse.de"
    end
    
    def repo_url
      'http://download.opensuse.org/distribution/13.2/repo/oss/media.1/build'
    end

    def openqa_version
      'SLES 12 SP1'
    end

    # Name of the ISO file by the given staging project tracked on openqa
    #
    # @return [String] file name
    def openqa_iso(project)
      ending = _project_iso(project)
      "SLE12-SP1-Staging:#{project.letter}-#{ending}"
    end

  end
end
