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
  s.rubyforge_project = "bcms_google_mini_search"

  s.files         = `git ls-files`.split("\n")
  # Exclude files required for the 'dummy' Rails app
  s.files         -= Dir['config/**/*', 'public/**/*', 'config.ru', 'db/**/*', 'script/**/*',
                         'app/controllers/application_controller.rb',
                         'app/helpers/application_helper.rb',
                         'app/layouts/templates/**/*'

  ]
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  s.add_dependency(%q<browsercms>, ["~> 3.3.0"])
end


