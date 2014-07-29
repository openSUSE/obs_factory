module ObsFactory
  class StagingProjectsController < ApplicationController
    respond_to :json, :html

    def index
      staging_projects = StagingProject.all
      respond_to do |format|
        format.html do
          @staging_projects = StagingProjectPresenter.wrap(staging_projects)
          @backlog_requests = Request.with_open_reviews_for(by_group: 'factory-staging')
          @backlog_requests.sort! { |x,y| x.package <=> y.package }
        end
        format.json { render json: staging_projects }
      end
    end

    def show
      staging_project = StagingProject.find(params[:id].upcase)
      respond_to do |format|
        format.html { @staging_project = StagingProjectPresenter.new(staging_project) }
        format.json { render json: staging_project }
      end
    end
  end
end
