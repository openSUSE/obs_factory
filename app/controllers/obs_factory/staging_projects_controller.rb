module ObsFactory
  class StagingProjectsController < ApplicationController
    respond_to :json, :html

    before_action :require_distribution
    
    def require_distribution
      @distribution = Distribution.find(params[:project])
      unless @distribution
        redirect_to main_app.root_path, flash: { error: "#{params[:project]} is not a valid openSUSE distribution, can't offer dashboard" }
      end
    end

    def index
      respond_to do |format|
        format.html do
          @staging_projects = StagingProjectPresenter.sort(@distribution.staging_projects)
          @backlog_requests = Request.with_open_reviews_for(by_group: 'factory-staging', target_project: @distribution.name)
          @backlog_requests.sort! { |x,y| x.package <=> y.package }
          # For the breadcrumbs
          @project = @distribution.project
        end
        format.json { render json: @distribution.staging_projects_all }
      end
    end

    before_action :require_id, only: [:show]

    def require_id
      @staging_project = StagingProject.find(@distribution, params[:id])
      unless @staging_project
        redirect_to main_app.root_path, flash: { error: "#{params[:id]} is not a valid staging project" }
      end
    end

    def show
      respond_to do |format|
        format.html do
          @staging_project = StagingProjectPresenter.new(@staging_project)
          # For the breadcrumbs
          @project = @distribution.project
        end
        format.json { render json: staging_project }
      end
    end
  end
end
