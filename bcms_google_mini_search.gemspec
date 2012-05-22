# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bcms_google_mini_search/version"

Gem::Specification.new do |s|
  s.name        = "bcms_google_mini_search"
  s.version     = BcmsGoogleMiniSearch::VERSION
  s.authors = ["BrowserMedia"]
  s.email = %q{github@browsermedia.com}
  s.homepage = %q{http://github.com/browsermedia/bcms_google_mini_search}
  s.description = %q{A Google Appliance module for BrowserCMS. Used to display search results from a Google Mini/Search Appliance on a site.}
  s.summary = %q{A Google Mini Search Module for BrowserCMS}
  s.extra_rdoc_files = [
      "README.markdown"
    ]
  s.rdoc_options = ["--charset=UTF-8"]
  s.rubyforge_project = s.name

  s.files = Dir["{app,config,db,lib}/**/*"]
  s.files += Dir["app/**/*"]
  s.files += Dir["config/**/*"]
  s.files += Dir["db/**/*"]
  s.files += Dir["lib/**/*"] 
  s.files += Dir["Gemfile", "LICENSE.txt", "COPYRIGHT.txt", "GPL.txt", "release_notes.txt" ]

  s.test_files += Dir["test/**/*"]
  s.test_files -= Dir['test/dummy/**/*']
  s.require_paths = ["lib"]
  s.add_dependency("browsercms", "< 3.6.0", ">= 3.5.0.rc2")
end


