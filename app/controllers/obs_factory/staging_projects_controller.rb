module ObsFactory
  class StagingProjectsController < ApplicationController
    respond_to :json, :html

    def index
      staging_projects = StagingProject.all
      respond_to do |format|
        format.html { @staging_projects = StagingProjectPresenter.wrap(staging_projects) }
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
