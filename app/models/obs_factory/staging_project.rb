require 'obs_factory/openqa'

module ObsFactory
  class StagingProject
    include ActiveModel::Serializers::JSON

    attr_accessor :project, :untracked_requests, :obsolete_requests,
      :unreviewed_requests, :buildstatus, :openqa, :subprojects

    OBSOLETE_STATES = %w(declined superseded revoked)

    def initialize(project)
      @openqa = ObsFactory::Openqa.new

      self.project = project
      self.obsolete_requests = BsRequestCollection.new(project: name, states: OBSOLETE_STATES).relation
      self.subprojects = Project.where(["name like ?", "#{name}:%"]).map { |p| StagingProject.new(p) }
      self.openqa = openqa_jobs
    end

    def name
      project.name
    end

    def description
      project.description
    end

    def openqa_jobs
      @openqa.get('jobs', iso: iso_name, scope: 'current')['jobs']
    end

    # TODO
    def iso_name
      'openSUSE-Staging:D-Staging-DVD-x86_64-Build92.4-Media.iso'
    end

    def attributes
      { 'name' => nil, 'description' => nil, 'obsolete_requests' => nil,
        'openqa' => nil, 'subprojects' => nil }
    end
  end
end
