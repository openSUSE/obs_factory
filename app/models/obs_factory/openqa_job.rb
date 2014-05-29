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

    def self.find_all_by(args)
      if args[:iso_name]
        jobs = @@api.get('jobs', iso: args[:iso_name], scope: 'current')['jobs']
        jobs.map { |j| OpenqaJob.new(j.slice(*attributes)) }
      else
        nil
      end
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
