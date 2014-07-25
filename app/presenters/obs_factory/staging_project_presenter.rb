module ObsFactory
  # View decorator for StagingProject
  class StagingProjectPresenter < BasePresenter

    # Wraps the associated openqa_jobs with the corresponding decorator.
    #
    # @return [Array] Array of OpenqaJobPresenter objects
    def openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(model.openqa_jobs)
    end

    # Wraps the associated subprojects with the corresponding decorator.
    #
    # @return [Array] Array of StagingProjectPresenter objects
    def subprojects
      ObsFactory::StagingProjectPresenter.wrap(model.subprojects)
    end

    # List of packages included in the staging_project.
    #
    # The names are extracted from the description (that is in fact a yaml
    # string).
    #
    # @return [String] package names delimited by commas
    def description_packages
      requests = meta["requests"]
      if requests.blank?
        ''
      else
        requests.map {|i| i["package"] }.sort.join(', ')
      end
    end

    # List of requests/packages tracked in the staging project
    def classified_requests
      requests = selected_requests
      return [] unless requests
      ret = []
      requests.each do |req|
        r = { id: req.id, package: req.package }
        css = 'ok'
        r[:missing_reviews] = missing_reviews[req.id]
        unless r[:missing_reviews].blank?
          css = 'review'
        end
        if req.obsolete?
          css = 'obsolete'
        end
        r[:css] = css
        ret << r
      end
      # now append untracked reqs
      untracked_requests.each do |req|
        ret << { id: req.id, package: req.package, css: 'untracked' }
      end
      ret.sort { |x,y| x['package'] <=> y['package'] }
    end
  end
end
