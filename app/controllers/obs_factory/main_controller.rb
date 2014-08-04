module ObsFactory
  class MainController < ApplicationController
    respond_to :html

    def dashboard
      @staging_projects = StagingProjectPresenter.sort(StagingProject.all)
      @backlog_requests = Request.with_open_reviews_for(by_group: 'factory-staging')
      @backlog_requests.sort! { |x,y| x.package <=> y.package }
    end

  end
end
