module ObsFactory

  # this class tracks the differences between Factory and the upcoming release
  class DistributionStrategyOpenSUSE < DistributionStrategyFactory
    def opensuse_version
      # Remove the "openSUSE:" part
      project.name[9..-1]
    end

    def opensuse_leap_version
      # Remove the "openSUSE:Leap:" part
      project.name[14..-1]
    end

    def openqa_version
      opensuse_leap_version
    end

    def openqa_group
      "openSUSE Leap #{opensuse_leap_version}"
    end

    def repo_url
      "http://download.opensuse.org/distribution/leap/#{opensuse_leap_version}/repo/oss/media.1/build"
    end

    def url_suffix
      "distribution/leap/#{opensuse_leap_version}/iso"
    end

    def openqa_iso_prefix
      "openSUSE-#{opensuse_version}-Staging"
    end

    def published_arch
      'x86_64'
    end

    # Version of the published distribution
    #
    # @return [String] version string
    def published_version
      begin
        f = open(repo_url)
      rescue OpenURI::HTTPError => e
        return 'unknown'
      end
      matchdata = %r{openSUSE-#{opensuse_leap_version}-#{published_arch}-Build(.*)}.match(f.read)
      matchdata[1]
    end

    # URL parameter for 42
    def openqa_filter(project)
      return "match=#{opensuse_leap_version}:S:#{project.letter}"
    end

  end
end
