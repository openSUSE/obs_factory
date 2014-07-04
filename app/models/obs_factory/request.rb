module ObsFactory
  # A covenient subset of BsRequest.
  #
  # It contains a reference to the corresponding BsRequest object, but exposing
  # the attributes and methods that are relevant to the engine in a more
  # convenient way.
  class Request
    include ActiveModel::Model
    extend ActiveModel::Naming
    include ActiveModel::Serializers::JSON

    attr_accessor :bs_request

    OBSOLETE_STATES = %w(declined superseded revoked)

    DELEGATED_METHODS = %w(id state description creator accept_at created_at updated_at reviews)

    # Delegate some methods to the associated BsRequest object
    DELEGATED_METHODS.each do |m|
      define_method(m) { bs_request.send(m) }
    end

    def initialize(bs_request = nil)
      self.bs_request = bs_request
    end

    # Requests with the given ids
    #
    # @param [Array] Array of ids
    # @return [Array]  Array of Request objects
    def self.find(ids)
      bs_requests = BsRequest.includes(:reviews, :bs_request_actions).find(ids)
      bs_requests.map {|r| Request.new(r) }
    end

    # Requests in 'review' state that have new reviews for the given project
    #
    # @param [String]  project_name  the name of the associated project
    # @return [Array]  Array of Request objects
    def self.with_open_reviews_for(project_name)
      reviews = Review.includes(:bs_request => [:reviews, :bs_request_actions])
      reviews = reviews.where(by_project: project_name, state: 'new', "bs_requests.state" => 'review')
      reviews.map {|r| Request.new(r.bs_request) }
    end

    # Checks if the request is obsolete
    #
    # @return [Boolean] true if the request is declined, superseded or revoked
    def obsolete?
      OBSOLETE_STATES.include? state
    end

    # Name of the original target package
    #
    # return [String] the name
    def package
      bs_request.bs_request_actions.first.target_package
    end

    # Id of the superseding request
    #
    # @return [Integer] id of request or nil if none
    def superseded_by_id
      bs_request.superseded_by ? (bs_request.superseded_by.to_i rescue nil) : nil
    end

    # Superseding request
    #
    # @return [Request] the request or nil if none
    def superseded_by
      superseded_by_id ? Request.find(superseded_by_id) : nil
    end

    def ==(req)
      id == req.id
    end

    def eql?(req)
      id == req.id
    end

    # Defined to enable the usage of Array#-
    def hash
      id.hash + 32 * bs_request.hash
    end

    def self.attributes
      DELEGATED_METHODS + %w(package superseded_by_id) - %w(reviews)
    end

    # Required by ActiveModel::Serializers
    def attributes
      Hash[self.class.attributes.map { |a| [a, nil] }]
    end
  end
end
