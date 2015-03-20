require 'test_helper'

class StagingProjectTest < ActiveSupport::TestCase
  fixtures :all

  test ".for" do
    factory = ObsFactory::Distribution.find("openSUSE:Factory")
    s_projects = ObsFactory::StagingProject.for(factory)
    assert_equal 4, s_projects.size
  end

  test ".find" do
    factory = ObsFactory::Distribution.find("openSUSE:Factory")
    s_project = ObsFactory::StagingProject.find(factory, "A:DVD")
    assert_equal "DVD subproject for Staging:A", s_project.description
  end

  test ".for" do
    factory = ObsFactory::Distribution.find("openSUSE:Factory:PowerPC")
    s_projects = ObsFactory::StagingProject.for(factoryppc)
    assert_equal 4, s_projects.size
  end

  test ".find" do
    factory = ObsFactory::Distribution.find("openSUSE:Factory:PowerPC")
    s_project = ObsFactory::StagingProject.find(factoryppc, "A:DVD")
    assert_equal "DVD subproject for Staging:A", s_project.description
  end
end
