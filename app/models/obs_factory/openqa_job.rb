module ObsFactory
  # Local representation of a job in the remote openQA. Uses a OpenqaApi (with a
  # hardcoded base url) to read the information and the Rails cache to store it
  class OpenqaJob
    include ActiveModel::Model
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :id, :name, :state, :result, :clone_id, :iso

    def self.openqa_base_url
      "https://openqa.opensuse.org"
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
      # per ISO name. That caching is currently not working because openQA does
      # not include an 'iso' attribute in the response. With the introduction of
      # 'assets' in openQA, this point is under discussion.
      if filter.empty?
        Rails.cache.delete('openqa_isos') if refresh
        jobs = []
        cached = true
        isos = Rails.cache.fetch('openqa_isos', expires_in: 20.minutes) do
          cached = false
          jobs = @@api.get('jobs', get_params)['jobs']
          jobs.group_by {|j| j['iso']}.each do |iso, iso_jobs|
            Rails.cache.write("openqa_jobs_for_iso_#{iso}", iso_jobs)
          end
          jobs.map {|j| j['iso']}.sort.uniq
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
          @@api.get('jobs', get_params)['jobs']
        end
      # In any other case, don't cache
      else
        get_params.merge!(filter)
        jobs = @@api.get('jobs', get_params)['jobs']
      end

      jobs.map { |j| OpenqaJob.new(j.slice(*attributes)) }
    end

    def self.attributes
      %w(id name state result clone_id iso)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end
  end
end
