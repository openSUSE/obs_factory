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

    def obsolete_requests
      @obsolete_requests ||= BsRequestCollection.new(project: name, states: OBSOLETE_STATES).relation
    end

    def subprojects
      @subprojects ||= Project.where(["name like ?", "#{name}:%"]).map { |p| StagingProject.new(p) }
    end

    def openqa_jobs
      @openqa_jobs ||= OpenqaJob.find_all_by(iso_name: iso_name)
    end

    # TODO
    def iso_name
      'openSUSE-Staging:D-Staging-DVD-x86_64-Build92.4-Media.iso'
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
