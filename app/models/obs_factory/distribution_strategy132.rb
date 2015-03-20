module ObsFactory

  # this class tracks the differences between factory and 13.2
  class DistributionStrategy132 < DistributionStrategyFactory

    def repo_url
      'http://download.opensuse.org/distribution/13.2/repo/oss/media.1/build'
    end

    def openqa_version
      '13.2'
    end

    def openqa_iso_prefix
      "openSUSE-13.2-Staging"
    end
  end
end
