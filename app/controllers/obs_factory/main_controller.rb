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

      @standard = ObsProject.new "openSUSE:Factory", 'standard'
      @standard.exclusive_repository = 'standard'
      @standard = ObsProjectPresenter.new(@standard)

      @live = ObsProject.new "openSUSE:Factory:Live", 'live'
      @live.exclusive_repository = 'standard'
      @live = ObsProjectPresenter.new(@live)

      @images = ObsProject.new "openSUSE:Factory", 'images'
      @images.exclusive_repository = 'images'
      @images = ObsProjectPresenter.new(@images)

      calculate_reviews
    end

    def calculate_reviews
      @reviews = {}
      @reviews[:review_team] = Request.with_open_reviews_for(by_group: 'opensuse-review-team').size
      @reviews[:repo_checker] = Request.with_open_reviews_for(by_user: 'factory-repo-checker').size
      @reviews[:factory_auto] = Request.with_open_reviews_for(by_group: 'factory-auto').size
      @reviews[:legal_auto] = Request.with_open_reviews_for(by_group: 'legal-auto').size
      @reviews[:legal_team] = Request.with_open_reviews_for(by_group: 'legal-team').size
    end
  end
end
