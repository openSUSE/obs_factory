module ObsFactory
  class BasePresenter < SimpleDelegator
    def self.wrap(collection)
      collection.map do |obj|
        new obj
      end
    end

    def model
      __getobj__
    end
  end
end
