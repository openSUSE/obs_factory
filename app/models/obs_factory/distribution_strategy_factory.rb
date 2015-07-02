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

    # Name of the ISO file by the given staging project tracked on openqa
    #
    # @return [String] file name
    def openqa_iso(project)
      iso = project_iso(project)
      return nil if iso.nil?
      ending = iso[5..-1] # Everything but the initial 'Test-'
      suffix = /DVD$/ =~ project.name ? 'Staging2' : 'Staging'
      self.openqa_iso_prefix + ":#{project.letter}-#{suffix}-DVD-#{arch}-#{ending}"
    end

    # Name of the ISO file produced by the given staging project's Test-DVD
    #
    # Not part of the Strategy API, but useful for subclasses
    #
    # @return [String] file name
    def project_iso(project)
      arch = self.arch
      buildresult = Buildresult.find_hashed(project: project.name, package: "Test-DVD-#{arch}",
                                            repository: 'images',
                                            view: 'binarylist')
      binaries = []
      # we get multiple architectures, but only one with binaries
      buildresult.elements('result') do |r|
        r['binarylist'].elements('binary') do |b|
          return b['filename'] if /\.iso$/ =~ b['filename']
        end
      end
      nil
    end
    protected :project_iso

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
