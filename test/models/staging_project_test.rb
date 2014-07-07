require 'test_helper'

class StagingProjectTest < ActiveSupport::TestCase
  fixtures :all

  test ".all" do
    s_projects = ObsFactory::StagingProject.all
    assert_equal 4, s_projects.size
  end

  test ".find" do
    s_project = ObsFactory::StagingProject.find("A:DVD")
    assert_equal "DVD subproject for Staging:A", s_project.description
  end
end
