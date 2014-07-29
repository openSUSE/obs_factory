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
        requests.map { |i| i["package"] }.sort.join(', ')
      end
    end

    # engine helpers are troublesome, so we avoid them
    def review_icon(reviewer)
      case reviewer
        when 'opensuse-review-team' then 'eye'
        when 'factory-repo-checker' then 'monitor'
        when 'legal-team' then 'script'
        else 'exclamation'
      end
    end

    # List of requests/packages tracked in the staging project
    def classified_requests
      return @classified_requests if @classified_requests

      @classified_requests = []
      requests = selected_requests
      return @classified_requests unless requests

      reviews = Hash.new
      missing_reviews.each do |r|
        reviews[r[:request]] ||= []
        r[:icon] = review_icon(r[:by])
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
        @classified_requests << r
      end
      # now append untracked reqs
      untracked_requests.each do |req|
        @classified_requests << { id: req.id, package: req.package, css: 'untracked' }
      end
      @classified_requests.sort! { |x, y| x[:package] <=> y[:package] }
      @classified_requests
    end

    # determine build progress as percentage 
    # if the project contains subprojects but is complete, the percentage
    # is the subproject's
    def build_progress
      total = 0
      final = 0
      building_repositories.each do |r|
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

    # @return [Array] Array of OpenqaJob objects for all subprojects
    def all_openqa_jobs
      ret = model.openqa_jobs
      subprojects.each do |prj|
        ret += prj.openqa_jobs
      end
      ret
    end

    # Wraps the associated openqa_jobs with the corresponding decorator.
    #
    # @return [Array] Array of OpenqaJobPresenter objects for all subprojects
    def openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(all_openqa_jobs)
    end

    # Wraps the failed openqa_jobs with the corresponding decorator.
    #
    # @return [Array] Array of OpenqaJobPresenter objects for all subprojects
    def failed_openqa_jobs
      ObsFactory::OpenqaJobPresenter.wrap(all_openqa_jobs.select {|job| job.failing_modules.present? })
    end

    # return a percentage counting the reviewed requests / total requests
    def review_percentage
      total = classified_requests.size
      missing = 0
      classified_requests.each do |rq|
        missing +=1 if rq[:missing_reviews]
      end
      100 - missing * 100 / total
    end

    def testing_percentage
      jobs = all_openqa_jobs
      notdone = 0
      jobs.each do |job|
        notdone += 1 unless %w(passed failed).include?(job.result)
      end
      100 - notdone * 100 / jobs.size
    end

    def first_running_openqa_job_link
      all_openqa_jobs.each do |job|
        unless %w(passed failed).include?(job.result)
          return ObsFactory::OpenqaJobPresenter.new(job).url
        end
      end
      ''
    end

  end
end
