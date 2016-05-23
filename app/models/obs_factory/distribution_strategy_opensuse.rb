module ObsFactory

  # this class tracks the differences between Factory and the upcoming release
  class DistributionStrategyOpenSUSE < DistributionStrategyFactory
    def opensuse_version
      # Remove the "openSUSE:" part
      project.name[9..-1]
    end

    def repo_url
      "http://download.opensuse.org/distribution/#{opensuse_version}/repo/oss/media.1/build"
    end

    def openqa_version
      opensuse_version
    end

    def openqa_iso_prefix
      "openSUSE-#{opensuse_version}-Staging"
    end

    # URL parameter for 42
    def openqa_filter(project)
      return "match=42:S:#{project.letter}"
    end

  end
end
