require 'test_helper'

class StagingProjectTest < ActiveSupport::TestCase
  fixtures :all

  test ".for" do
    staging_count = {
      "openSUSE:Factory"          => 4,
      "openSUSE:Factory:PowerPC"  => 4,
      "openSUSE:13.2"             => 2 }

    staging_count.each_pair do |name, count|
      distro = ObsFactory::Distribution.find(name)
      s_projects = ObsFactory::StagingProject.for(distro)
      assert_equal count, s_projects.size
    end
  end

  test ".find" do
    factory = ObsFactory::Distribution.find("openSUSE:Factory")
    factoryppc = ObsFactory::Distribution.find("openSUSE:Factory:PowerPC")
    osuse132 = ObsFactory::Distribution.find("openSUSE:13.2")

    s_project = ObsFactory::StagingProject.find(factory, "A:DVD")
    assert_equal "DVD subproject for Staging:A", s_project.description

    s_project = ObsFactory::StagingProject.find(factoryppc, "A:DVD")
    assert_equal "DVD subproject for Staging:A", s_project.description

    s_project = ObsFactory::StagingProject.find(osuse132, "A:DVD")
    assert_equal nil, s_project

    s_project = ObsFactory::StagingProject.find(osuse132, "A")
    assert_equal "Staging A for 13.2", s_project.description
  end
end
