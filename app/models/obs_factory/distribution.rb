require 'open-uri'

module ObsFactory
  
  class UnknownDistribution < Exception
  end
  
  # A Distribution. Contains a reference to the corresponding Project object.
  class Distribution
    include ActiveModel::Model
    extend ActiveModel::Naming
    extend Forwardable
    
    SOURCE_VERSION_FILE = "_product/openSUSE.product"
    RINGS_PREFIX = ":Rings"

    attr_accessor :project, :strategy

    def distribution_strategy_for_project(project)
      s = case project.name
        when 'openSUSE:Factory' then DistributionStrategyFactory.new
        when 'openSUSE:Factory:PowerPC' then DistributionStrategyFactoryPPC.new
        when 'openSUSE:13.2' then DistributionStrategy132.new
        else raise UnknownDistribution
      end
      s.project = project
      s
    end

    def initialize(project = nil)
      self.project = project
      self.strategy = distribution_strategy_for_project(project)
    end

    def self.attributes
      %w(name description staging_projects openqa_version
      source_version totest_version published_version
      standard_project live_project images_project ring_projects)
    end

    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end

    def_delegators :@strategy, :root_project_name, :url_suffix, :openqa_version,
                               :openqa_iso_prefix, :arch

    # Find a distribution by id
    #
    # @return [Distribution] the distribution
    def self.find(id)
      project = ::Project.find_by_name(id)
      if project
        begin
          Distribution.new(project)
        rescue UnknownDistribution
          nil
        end
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

    # Id of the distribution
    #
    # @return [String] name
    def id
      name
    end

    # Description of the associated project
    #
    # @return [String] description of the Project object
    def description
      project.description
    end

    # Version of the distribution used as ToTest
    #
    # @return [String] version string
    def totest_version
      Rails.cache.fetch("totest_version_for_#{name}", expires_in: 10.minutes) do
        strategy.totest_version
      end
    end

    # Version of the published distribution
    #
    # @return [String] version string
    def published_version
      Rails.cache.fetch("published_version_for_#{name}", expires_in: 10.minutes) do
        strategy.published_version
      end
    end

    # Staging projects associated to the distribution
    #
    # @return [Array] array of StagingProject objects
    def staging_projects
      @staging_projects ||= StagingProject.for(self)
    end

    # Staging project associated to the distribution and with the given id
    #
    # @param [String] id of the staging project
    # @return [StagingProject] the associated project or nil
    def staging_project(id)
      if @staging_projects
        @staging_projects.select {|p| p.id == id }
      else
        StagingProject.find(self, id)
      end
    end

    # Version of the distribution used as source
    #
    # @return [String] version string
    def source_version
      Rails.cache.fetch("source_version_for_#{name}", expires_in: 10.minutes) do
        begin
          p = Xmlhash.parse(ActiveXML::backend.direct_http "/source/#{name}/#{SOURCE_VERSION_FILE}")
          p.get('products').get('product').get('version')
        rescue ActiveXML::Transport::NotFoundError
          nil
        end
      end
    end

    # openQA jobs related with a given version of the distribution
    #
    # @param [#to_s] version must be :source, :totest or :published
    # @return [Array] list of OpenqaJob objects
    def openqa_jobs_for(version)
      filter = {distri: 'opensuse', version: strategy.openqa_version, build: send(:"#{version}_version")}
      OpenqaJob.find_all_by(filter, exclude_modules: true)
    end

    # Requests with some open review targeting the distribution, filtered by
    # the group in charge of the open reviews
    #
    # @param [String] group name of the group
    # @return [Array] list of Request objects
    def requests_with_reviews_for_group(group)
      Request.with_open_reviews_for(by_group: group, target_project: name)
    end

    # Requests with some open review targeting the distribution, filtered by
    # the user in charge of the open reviews
    #
    # @param [String] user name of the user
    # @return [Array] list of Request objects
    def requests_with_reviews_for_user(user)
      Request.with_open_reviews_for(by_user: user, target_project: name)
    end

    # Standard project
    #
    # @return [ObsProject] standard
    def standard_project
      if @standard_project.nil?
        @standard_project = ObsProject.new(name, 'standard')
        @standard_project.exclusive_repository = 'standard'
      end
      @standard_project
    end

    # Live project
    #
    # @return [ObsProject] live
    def live_project
      if @live_project.nil?
        @live_project = ObsProject.new("#{name}:Live", 'live')
        if @live_project.project.nil?
          @live_project = nil
        else
          @live_project.exclusive_repository = 'standard'
        end
      end
      @live_project
    end

    # Images project
    #
    # @return [ObsProject] images
    def images_project
      if @images_project.nil?
        @images_project = ObsProject.new(name, 'images')
        @images_project.exclusive_repository = 'images'
      end
      @images_project
    end

    # Projects defining the distribution rings
    #
    # @return [Array] list of ObsProject objects nicknamed with numbers
    def ring_projects
      @ring_projects ||= strategy.rings.each_with_index.map do |r,idx|
        ObsProject.new("#{rings_project_name}:#{idx}-#{r}", "#{idx}-#{r}")
      end
    end

    # Name of the project used as top-level for the ring projects
    #
    # @return [String] project name
    def rings_project_name
      "#{root_project_name}#{RINGS_PREFIX}"
    end
  end
end
