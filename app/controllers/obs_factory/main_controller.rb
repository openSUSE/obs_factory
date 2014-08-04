require 'open-uri'

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
      gather_versions
      openqa_summary(@versions[:totest])

    end

    def calculate_reviews
      @reviews = {}
      @reviews[:review_team] = Request.with_open_reviews_for(by_group: 'opensuse-review-team').size
      @reviews[:repo_checker] = Request.with_open_reviews_for(by_user: 'factory-repo-checker').size
      @reviews[:factory_auto] = Request.with_open_reviews_for(by_group: 'factory-auto').size
      @reviews[:legal_auto] = Request.with_open_reviews_for(by_group: 'legal-auto').size
      @reviews[:legal_team] = Request.with_open_reviews_for(by_group: 'legal-team').size
    end

    def gather_versions
      @versions = Rails.cache.fetch('versions2', expires_in: 10.minutes) do
        { source: parse_product,
          totest: check_totest,
          published: check_download_server }
      end
    end

    def check_totest
      d = Xmlhash.parse(ActiveXML::backend.direct_http '/build/openSUSE:Factory:ToTest/images/local/_product:openSUSE-cd-mini-x86_64')
      d.elements('binary') do |b|
        matchdata = %r{.*Snapshot(.*)-Media\.iso$}.match(b['filename'])
        return matchdata[1] if matchdata
      end
    end

    def check_download_server
      f = open("http://download.opensuse.org/factory/repo/oss/media.1/build")
      matchdata = %r{openSUSE-(.*)-i586-.*}.match(f.read)
      return matchdata[1]
    end

    def parse_product
      p = Xmlhash.parse(ActiveXML::backend.direct_http '/source/openSUSE:Factory/_product/openSUSE.product')
      p.get('products').get('product').get('version')
    end

    def openqa_summary(build)
      @openqa = {build: build, passed: 0, failed: 0, unknown: 0, incomplete: 0, none: 0}

      f = open("http://openqa.opensuse.org/api/v1/jobs?version=FTT&distri=opensuse&build=#{build}&scope=current")
      json = Yajl::Parser.new.parse(f)
      json['jobs'].each do |job|
        next if job['clone_id']
        @openqa[job['result'].to_sym] += 1
      end
    end
  end
end
