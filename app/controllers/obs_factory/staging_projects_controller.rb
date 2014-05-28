module ObsFactory
  class StagingProjectsController < ApplicationController
    respond_to :json, :html

    def list
      @projects = Project.where(["name like ?", 'openSUSE:Factory:Staging:_'])
      @staging_projects = @projects.map { |p| StagingProject.new(p) }
      respond_to do |format|
        format.json { render json: @staging_projects }
      end
    end
  end
end
