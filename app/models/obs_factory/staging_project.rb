module ObsFactory
  class StagingProject
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :project

    OBSOLETE_STATES = %w(declined superseded revoked)

    def initialize(project = nil)
      self.project = project
    end

    def name
      project.name
    end

    def description
      project.description
    end

    def letter
      name.split(':').detect {|i| i.length == 1 }
    end

    def obsolete_requests
      @obsolete_requests ||= BsRequestCollection.new(project: name, states: OBSOLETE_STATES).relation
    end

    def subprojects
      @subprojects ||= Project.where(["name like ?", "#{name}:%"]).map { |p| StagingProject.new(p) }
    end

    def openqa_jobs
      @openqa_jobs ||= iso.nil? ? [] : OpenqaJob.find_all_by(iso: iso)
    end

    def broken_packages
      set_buildinfo if @broken_packages.nil?
      @broken_packages
    end

    def building_repositories
      set_buildinfo if @building_repositories.nil?
      @building_repositories
    end

    def iso
      return @iso if @iso
      buildresult = Buildresult.find_hashed(project: name, package: 'Test-DVD-x86_64',
                                            repository: 'images', arch: 'x86_64',
                                            view: 'binarylist')
      binaries = buildresult['result']['binarylist']['binary']
      return nil if binaries.nil?
      binary = binaries.detect { |l| /\.iso$/ =~ l['filename'] }
      return nil if binary.nil?
      ending = binary['filename'][5..-1] # Everything but the initial 'Test-'
      suffix = /DVD$/ =~ name ? 'Staging2' : 'Staging'
      @iso = "openSUSE-Staging:#{letter}-#{suffix}-DVD-x86_64-#{ending}"
    end

    # Coming next: untracked_requests, unreviewed_requests
    def self.attributes
      %w(name description obsolete_requests openqa_jobs building_repositories broken_packages subprojects)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end

    protected

    def set_buildinfo
      buildresult = Buildresult.find_hashed(project: name, code: %w(failed broken unresolvable))
      @broken_packages = []
      @building_repositories = []
      buildresult['result'].each do |result|
        building = false
        if !%w(published unpublished).include?(result['state']) || result['dirty'] == 'true'
          building = true
          @building_repositories << result.slice('repository', 'arch', 'code', 'state', 'dirty')
        end
        if statuses = result['status']
          statuses.each do |status|
            if status.kind_of?(Hash) && code = status['code']
              if %w(broken failed).include?(code) || (code == 'unresolvable' && !building)
                @broken_packages << { 'package' => status['package'],
                                      'state' => code,
                                      'details' => status['details'],
                                      'repository' => result['repository'],
                                      'arch' => result['arch'] }
              end
            end
          end
        end
      end
    end
  end
end
