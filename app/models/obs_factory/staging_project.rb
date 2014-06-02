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

    # Coming next: untracked_requests, unreviewed_requests, buildstatus
    def self.attributes
      %w(name description obsolete_requests openqa_jobs subprojects)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end
  end
end
