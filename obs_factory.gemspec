$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "obs_factory/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "obs_factory"
  s.version     = ObsFactory::VERSION
  s.authors     = ["openSUSE Team at SUSE"]
  s.email       = ["ancor@suse.de"]
  s.homepage    = "https://github.com/openSUSE-Team/"
  s.summary     = "Plugin for Open Build Service to manage openSUSE Factory related stuff."
  s.description = "This plugin adds capabilities improve the management of staging projects and Factory-To-Test."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2.2"
end
