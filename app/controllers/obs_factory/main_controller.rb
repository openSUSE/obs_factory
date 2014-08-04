module ObsFactory
  class MainController < ApplicationController
    respond_to :html

    def ring_project(suffix, nick)
      ObsProjectPresenter.new(ObsProject.new "openSUSE:Factory:Rings:#{suffix}", nick)
    end

    def dashboard
      @staging_projects = StagingProjectPresenter.sort(StagingProject.all)
      @ring_prjs = [ring_project('0-Bootstrap', '0'),
                    ring_project('1-MinimalX', '1'),
                    ring_project('2-TestDVD', '2')]
    end

  end
end
