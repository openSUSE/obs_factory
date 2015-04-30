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

    def openqa_iso_prefix
      "SLE-Staging"
    end
  end
end
