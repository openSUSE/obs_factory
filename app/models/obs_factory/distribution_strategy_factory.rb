module ObsFactory

  # this is not a Factory pattern, this is for openSUSE:Factory :/
  class DistributionStrategyFactory

    attr_accessor :project

    # String to pass as version to filter the openQA jobs
    #
    # @return [String] version parameter
    def openqa_version
      'Tumbleweed'
    end

    # Name of the project used as top-level for the staging projects and
    # the rings
    #
    # @return [String] project name
    def root_project_name
      project.name
    end

    def totest_version_file
      'images/local/_product:openSUSE-cd-mini-x86_64'
    end

    def arch
      'x86_64'
    end

    def url_suffix
      'factory/iso'
    end

    def rings
      %w(Bootstrap MinimalX TestDVD)
    end

    def repo_url
      'http://download.opensuse.org/factory/repo/oss/media.1/build'
    end

    def published_arch
      'i586'
    end

    # the prefix openQA gives test ISOs
    #
    # @return [String] e.g. 'openSUSE-Staging'
    def openqa_iso_prefix
      "openSUSE-Staging"
    end

    # Version of the distribution used as ToTest
    #
    # @return [String] version string
    def totest_version
      begin
        d = Xmlhash.parse(ActiveXML::backend.direct_http "/build/#{project.name}:ToTest/#{totest_version_file}")
        d.elements('binary') do |b|
          matchdata = %r{.*Snapshot(.*)-Media\.iso$}.match(b['filename'])
          return matchdata[1] if matchdata
        end
      rescue
        nil
      end
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
      matchdata = %r{openSUSE-(.*)-#{published_arch}-.*}.match(f.read)
      matchdata[1]
    end
  end
end
