module ObsFactory
  # A wrapper around Project, containing a reference to the original Project
  # object and adding some methods and attributes.
  class ObsProject

    attr_accessor :project, :nickname, :exclusive_repository

    def initialize(name, nick)
      self.project = Project.find_by_name(name)
      self.nickname = nick
    end

    # Name of the associated project
    #
    # @return [String] the name
    def name
      project.name
    end

    # Repository names defined for the project
    #
    # @return [Array] list of names
    def repos
      ret = {}
      build_summary.elements('result') do |r|
        ret[r['repository']] = 1
      end
      ret.keys
    end

    # Hashed summary of the build results.
    #
    # Cached during 5 minutes from the backend.
    #
    # @return [XMLHash] summary
    def build_summary
      obs_api = ObsFactory::ObsApi.new
      if obs_api.use_api?
        params = {"view" => 'summary'}
        obs_api.geturl(name, params)
      else
        Rails.cache.fetch("build_summary_for_#{name}", expires_in: 5.minutes) do
          ::Buildresult.find_hashed(project: name, view: 'summary')
        end
      end
    end

    # Number of build failures in the project
    #
    # @return [Integer] failures count
    def build_failures_count
      obs_api = ObsFactory::ObsApi.new
      if obs_api.use_api?
        params = {"code" => "%w(failed broken unresolvable)"}
        buildresult = obs_api.geturl(name, params)
      else
        buildresult = Buildresult.find_hashed(project: name, code: %w(failed broken unresolvable))
      end
      bp = {}
      buildresult.elements('result') do |result|
        result.elements('status') do |s|
          bp[s['package']] = 1
        end
      end
      bp.keys.count
    end
  end
end
