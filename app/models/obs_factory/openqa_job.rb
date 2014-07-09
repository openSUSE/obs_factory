module ObsFactory
  # Local representation of a job in the remote openQA. Uses a OpenqaApi (with a
  # hardcoded base url) to read the information and the Rails cache to store it
  class OpenqaJob
    include ActiveModel::Model
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :id, :name, :state, :result, :clone_id, :iso, :modules

    def self.openqa_base_url
      # build.opensuse.org can reach only the host directly, so we need
      # to use http - and accept a https redirect if used on work stations
      "http://openqa.opensuse.org"
    end

    @@api = ObsFactory::OpenqaApi.new(openqa_base_url)

    # Reads jobs from the openQA instance or the cache with an interface similar
    # to ActiveRecord::Base#find_all_by
    #
    # If searching by iso or getting the full list, caching comes into play. In
    # any other case, a GET query to openQA is always performed.
    # :cache == 'refresh' can be used in the 'opt' (second param) to force a
    # refresh of the cache.
    def self.find_all_by(args = {}, opt = {})
      refresh = (opt.symbolize_keys[:cache].to_s == 'refresh')
      filter = args.symbolize_keys.slice(:iso, :state, :build, :maxage)

      # We are only interested in current results
      get_params = {scope: 'current'}

      # If searching for the whole list of jobs, it caches the jobs
      # per ISO name.
      if filter.empty?
        Rails.cache.delete('openqa_isos') if refresh
        jobs = []
        cached = true
        isos = Rails.cache.fetch('openqa_isos', expires_in: 20.minutes) do
          cached = false
          jobs = @@api.get('jobs', get_params)['jobs']
          jobs.group_by {|j| (j['assets']['iso'].first rescue nil)}.each do |iso, iso_jobs|
            iso_jobs.each do |job|
              job['modules'] = modules_for(job['id'])
            end
            Rails.cache.write("openqa_jobs_for_iso_#{iso}", iso_jobs)
          end
          jobs.map {|j| (j['assets']['iso'].first rescue nil)}.sort.compact.uniq
        end
        if cached
          (isos + [nil]).each do |iso|
            jobs += Rails.cache.read("openqa_jobs_for_iso_#{iso}") || []
          end
        end
      # If searching only by ISO, cache that one
      elsif filter.keys == [:iso]
        get_params[:iso] = filter[:iso]
        cache_entry = "openqa_jobs_for_iso_#{filter[:iso]}"
        Rails.cache.delete(cache_entry) if refresh
        jobs = Rails.cache.fetch(cache_entry, expires_in: 20.minutes) do
          iso_jobs = @@api.get('jobs', get_params)['jobs']
          iso_jobs.map {|job| job.merge('modules' => modules_for(job['id'])) }
        end
      # In any other case, don't cache
      else
        get_params.merge!(filter)
        jobs = @@api.get('jobs', get_params)['jobs']
        jobs.each do |job|
          job['modules'] = modules_for(job['id'])
        end
      end

      jobs.map { |j| OpenqaJob.new(j.slice(*attributes)) }
    end

    # Name of the modules which failed during openQA execution
    #
    # @return [Array] array of module names
    def failing_modules
      modules.reject {|m| %w(ok na).include? m['result']}.map {|m| m['name'] }
    end

    def self.attributes
      %w(id name state result clone_id iso modules)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end

    protected

    # Reads the list of failed modules for a given job_id from openQA
    # by means of a GET call
    #
    # @param [#to_s]  job_id  the job id
    # @return [Array]  array of hashes with two keys each: 'name' and 'result'
    def self.modules_for(job_id)
      # Surprisingly, we don't have an API call for getting the job
      # results in openQA
      result = @@api.get("tests/#{job_id}/file/results.json", {}, base_url: openqa_base_url)
      result['testmodules'].map {|m| m.slice('name', 'result') }
    rescue
        []
    end
  end
end
