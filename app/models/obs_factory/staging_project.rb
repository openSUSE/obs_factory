module ObsFactory
  # A staging project. Contains a reference to the corresponding Project object.
  class StagingProject
    include ActiveModel::Model
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :project

    OBSOLETE_STATES = %w(declined superseded revoked)
    NAME_PREFIX = "openSUSE:Factory:Staging:"

    def initialize(project = nil)
      self.project = project
    end

    # Find all top-level staging projects
    #
    # @return [Array] array of StagingProject objects
    def self.all
      Project.where(["name like ?", "#{NAME_PREFIX}_"]).map { |p| StagingProject.new(p) }
    end

    # Find a staging project by id
    #
    # @return [StagingProject] the project
    def self.find(id)
      project = Project.find_by_name("#{NAME_PREFIX}#{id}")
      if project
        StagingProject.new(project)
      else
        nil
      end
    end

    # Name of the associated project
    #
    # @return [String] name of the Project object
    def name
      project.name
    end

    # Description of the associated project
    #
    # @return [String] description of the Project object
    def description
      project.description
    end

    # Letter of the staging project, extracted from its name
    #
    # @return [String] just the letter
    def letter
      name[NAME_PREFIX.size, 1]
    end

    # Id of the staging project, extracted from its name
    #
    # @return [String] the name excluding the common prefix
    def id
      name[NAME_PREFIX.size..-1]
    end

    # Requests that are selected into the project but should be not longer valid
    # due to its state (declined, superseded or revoked).
    #
    # @return [ActiveRecord::Relation] Obsolete requests
    def obsolete_requests
      selected_requests.select(&:obsolete?)
    end

    # Staging projects that are subprojects of this one, according to their names.
    #
    # Used to fetch the :DVD project
    #
    # @return [Array] Array of StagingProject objects
    def subprojects
      @subprojects ||= Project.where(["name like ?", "#{name}:%"]).map { |p| StagingProject.new(p) }
    end

    # Associated openQA jobs.
    #
    # The jobs are fetched by ISO name.
    # @see #iso
    #
    # @return [Array] Array of OpenqaJob objects
    def openqa_jobs
      @openqa_jobs ||= iso.nil? ? [] : OpenqaJob.find_all_by(iso: iso)
    end

    # Packages included in the staging project that are not building properly.
    #
    # Every broken package is represented by a hash with the following keys:
    # 'package', 'state', 'details', 'repository', 'arch'
    #
    # @return [Array] Array of hashes
    def broken_packages
      set_buildinfo if @broken_packages.nil?
      @broken_packages
    end

    # Repositories referenced in the staging project that are still building
    #
    # Every building repository is represented by a hash with the following keys:
    # 'repository', 'arch', 'code', 'state', 'dirty'
    #
    # @return [Array] Array of hashes
    def building_repositories
      set_buildinfo if @building_repositories.nil?
      @building_repositories
    end

    # Requests with open reviews but that are not selected into the staging
    # project
    #
    # @return [Array] Array of Request objects
    def untracked_requests
      open_requests - selected_requests
    end

    # Requests with open reviews
    #
    # @return [Array] Array of BsRequest objects
    def open_requests
      @open_requests ||= Request.with_open_reviews_for(by_project: name)
    end

    # Requests selected in the project
    #
    # @return [Array] Array of BsRequest objects
    def selected_requests
      if @selected_requests.nil?
        requests = meta["requests"]
        if requests
          ids = requests.map { |i| i['id'].to_i }
          @selected_requests = Request.find(ids)
        else
          @selected_requests = []
        end
      end
      @selected_requests
    end

    # Reviews that need to be accepted in order to be able to accept the
    # project.
    #
    # Reviews associated with the project that either are not accepted either
    # have the 'by_project' attribute set to the staging project.
    #
    # @return [Array] array of hashes with the following keys: :id, :state,
    #                 :request, :package and :by.
    def missing_reviews
      if @missing_reviews.nil?
        @missing_reviews = []
        attribs = [:by_group, :by_user, :by_project, :by_package]

        (open_requests + selected_requests).uniq.each do |req|
          req.reviews.each do |rev|
            unless rev.state.to_s == 'accepted' || rev.by_project == name
              # FIXME: this loop (and the inner if) would not be needed
              # if every review only has one valid by_xxx.
              # I'm keeping it to mimic the python implementation.
              # Instead, we could have something like
              # who = rev.by_group || rev.by_user || rev.by_project || rev.by_package
              attribs.each do |att|
                if who = rev.send(att)
                  @missing_reviews << { id: rev.id, request: req.id, state: rev.state.to_s, package: req.package, by: who }
                end
              end
            end
          end
        end
      end
      @missing_reviews
    end

    # Metadata stored in the description field
    #
    # @return [Hash] Hash with the metadata (currently the list of requests)
    def meta
      @meta ||= YAML.load(description) || {}
    end

    # Name of the ISO file generated by the staging project.
    #
    # @return [String] file name
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

    def self.attributes
      %w(name description obsolete_requests openqa_jobs building_repositories
        broken_packages subprojects untracked_requests missing_reviews selected_requests overall_state )
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end

    def build_state
      return :building if building_repositories.present?
      return :unacceptable if broken_packages.present?
      # check openQA jobs for all projects not building right now - or that are known to be broken
      openqa_jobs.each do |job|
        if job.failing_modules.present?
          return :failed
        elsif job.result != 'passed'
          return :testing
        end
      end
      return :acceptable
    end

    # calculate the overall state of the project
    def overall_state
      return @state unless @state.nil?
      @state = :empty

      if selected_requests.empty?
        return @state
      end

      # base state
      if untracked_requests.present? || obsolete_requests.present?
        @state = :unacceptable
      else
        @state = build_state
      end

      if @state == :acceptable
        subprojects.each do |prj|
          # we only have one subprj, so we don't have to worry overwriting 
          @state = prj.build_state
        end
      end

      if @state == :acceptable && missing_reviews.present?
        @state = :review
      end

      @state
    end

    protected

    # Used internally to calculate #broken_packages and #building_repositories
    def set_buildinfo
      buildresult = Buildresult.find_hashed(project: name, code: %w(failed broken unresolvable))
      @broken_packages = []
      @building_repositories = []
      buildresult.elements('result') do |result|
        building = false
        if !%w(published unpublished).include?(result['state']) || result['dirty'] == 'true'
          building = true
        end
        result.elements('status') do |status|
          code = status.get('code')
          if %w(broken failed).include?(code) || (code == 'unresolvable' && !building)
            @broken_packages << { 'package' => status['package'],
                                  'project' => name,
                                  'state' => code,
                                  'details' => status['details'],
                                  'repository' => result['repository'],
                                  'arch' => result['arch'] }
          end
        end
        if building
          # determine build summary
          current_repo = result.slice('repository', 'arch', 'code', 'state', 'dirty')
          current_repo[:tobuild] = 0
          current_repo[:final] = 0

          buildresult = Buildresult.find_hashed(project: name, view: 'summary', repository: current_repo['repository'], arch: current_repo['arch'])
          buildresult = buildresult.get('result').get('summary')
          buildresult.elements('statuscount') do |sc|
            if %w(excluded broken failed unresolvable succeeded excluded disabled).include?(sc['code'])
              current_repo[:final] += sc['count'].to_i
            else
              current_repo[:tobuild] += sc['count'].to_i
            end
          end
          @building_repositories << current_repo
        end
      end
      if @building_repositories.present?
        @broken_packages = @broken_packages.select { |p| p['state'] != 'unresolvable' }
      end
    end
  end
end
