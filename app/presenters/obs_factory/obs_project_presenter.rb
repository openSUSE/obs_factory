module ObsFactory

  # View decorator for a Project
  class ObsProjectPresenter < BasePresenter

    def build_summary_
      @build_summary ||= Rails.cache.fetch("build_summary_#{name}", expires_in: 5.minutes) do
        Buildresult.find_hashed(project: name, view: 'summary')
      end
    end

    def build_and_failed_params
      params = { project: self.name, defaults: 0 }
      Buildresult.avail_status_values.each do |s|
        next if %w(succeeded excluded).include? s.to_s
        params[s] = 1
      end

      self.repos.each do |r|
        params["repo_#{r}"] = 1
      end
      # hard code the archs we care for
      params['arch_i586'] = 1
      params['arch_x86_64'] = 1
      params['arch_local'] = 1
      params
    end

    def repos
      ret = {}
      build_summary_.elements('result') do |r|
        ret[r['repository']] = 1
      end
      ret.keys
    end

    def summary
      building = false
      failed = 0
      final = 0
      total = 0

      # first calculate the building state
      build_summary_.elements('result') do |result|
        Rails.logger.debug "RRR #{result.inspect}"
        if !%w(published unpublished).include?(result['state']) || result['dirty'] == 'true'
          building = true
        end
      end
      build_summary_.elements('result') do |result|
        result['summary'].elements('statuscount') do |sc|
          code = sc['code']
          count = sc['count'].to_i
          next if code == 'excluded' # plain ignore
          total += count
          if code == 'unresolvable'
            if building # only count if finished
              failed += count
            end
            next
          end
          if %w(broken failed).include?(code)
            failed += count
          else
            final += count
          end
        end
      end
      Rails.logger.debug "TTT #{total} #{final} #{failed} #{building}"
      build_progress =  (100 * (final + failed)) / total
      if building
        [:building, "#{self.nickname}: #{build_progress}%"]
      elsif failed > 0
        [:failed, "#{self.nickname}: #{failed}"]
      else
        [:succeeded, "#{self.nickname}: DONE"]
      end
    end
  end
end
