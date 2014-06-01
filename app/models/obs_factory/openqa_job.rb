module ObsFactory
  class OpenqaJob
    include ActiveModel::Model
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :id, :name, :state, :result, :clone_id

    def self.openqa_base_url
      "https://openqa.opensuse.org"
    end

    @@api = ObsFactory::OpenqaApi.new(openqa_base_url)

    def self.find_all_by(args = {}, opt = {})

      # We are only interested in current results
      get_params = {scope: 'current'}

      if iso = args[:iso_name]
        get_params[:iso] = iso
        cache_entry = "openqa_jobs_for_iso_#{iso}"
      else
        # FIXME: it's almost for sure too big for a single memcached entry
        cache_entry = "openqa_jobs"
      end

      Rails.cache.delete(cache_entry) if opt.symbolize_keys[:cache].to_s == 'refresh'
      jobs = Rails.cache.fetch(cache_entry, expires_in: 20.minutes) do
        @@api.get('jobs', get_params)['jobs']
      end
      jobs.map { |j| OpenqaJob.new(j.slice(*attributes)) }
    end

    def self.attributes
      %w(id name state result clone_id)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end
  end
end
