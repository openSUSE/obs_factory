module ObsFactory
  # View decorator for StagingProject
  class StagingProjectPresenter < BasePresenter

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
      reviews = Hash.new
      missing_reviews.each do |r|
        reviews[r[:request]] ||= []
        reviews[r[:request]] << r
      end
      requests.each do |req|
        r = { id: req.id, package: req.package }
        css = 'ok'
        r[:missing_reviews] = reviews[req.id]
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

    # determine build progress as percentage 
    # if the project contains subprojects but is complete, the percentage
    # is the subproject's
    def build_progress
      total = 0
      final = 0
      building_repositories.each do |r|
        Rails.logger.debug "BR #{r.inspect}"
        total += r[:tobuild] + r[:final]
        final += r[:final]
      end
      ret = { subproject: name }
      if total != 0
        ret[:percentage] = final * 100 / total
      else
        ret[:percentage] = 100
        subprojects.each do |prj|
          # we only have one subprj or none
          return prj.build_progress
        end
      end
      ret
    end

    # collect the broken packages of all subprojects
   def broken_packages
     ret = model.broken_packages
     subprojects.each do |prj|
       ret += prj.broken_packages
     end
     ret
   end

    # Wraps the associated openqa_jobs with the corresponding decorator.
    #
    # @return [Array] Array of OpenqaJobPresenter objects for all subprojects
   def openqa_jobs
     ret = model.openqa_jobs
     subprojects.each do |prj|
       ret += prj.openqa_jobs
     end
     ObsFactory::OpenqaJobPresenter.wrap(ret)
   end
  end
end
