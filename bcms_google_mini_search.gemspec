# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{bcms_google_mini_search}
  s.version = ""

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["BrowserMedia"]
  s.date = %q{2010-08-18}
  s.description = %q{Allows developers to integrate Google Mini or Google Search appliance into their CMS sites. Can be used to fetch search results and format them.}
  s.email = %q{github@browsermedia.com}
  s.extra_rdoc_files = [
    "README.markdown"
  ]
  s.files = [
    "app/controllers/application_controller.rb",
     "app/helpers/application_helper.rb",
     "app/models/search_result.rb",
     "app/portlets/google_mini_search_engine_portlet.rb",
     "app/portlets/search_box_portlet.rb",
     "app/views/portlets/google_mini_search_engine/_form.html.erb",
     "app/views/portlets/google_mini_search_engine/render.html.erb",
     "app/views/portlets/search_box/_form.html.erb",
     "app/views/portlets/search_box/render.html.erb",
     "lib/bcms_google_mini_search.rb",
     "lib/bcms_google_mini_search/routes.rb",
     "rails/init.rb"
  ]
  s.homepage = %q{http://www.browsercms.org}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{bcms_google_mini_search}
  s.rubygems_version = %q{1.3.7}
  s.summary = %q{A Google Mini Search Module for BrowserCMS}
  s.test_files = [
    "test/performance/browsing_test.rb",
     "test/test_helper.rb",
     "test/unit/helpers/search_engine_helper_test.rb",
     "test/unit/portlets/google_mini_search_engine_portlet_test.rb",
     "test/unit/portlets/search_box_portlet_test.rb",
     "test/unit/search_result_test.rb"
  ]

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
    else
    end
  else
  end
end

