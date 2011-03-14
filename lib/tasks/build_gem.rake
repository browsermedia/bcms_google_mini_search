begin
  require 'jeweler'
  Jeweler::Tasks.new do |spec|
    spec.name = "bcms_google_mini_search"
    spec.rubyforge_project = spec.name
    spec.summary = "A Google Mini Search Module for BrowserCMS"
    spec.description = "Allows developers to integrate Google Mini or Google Search Appliance into their CMS sites. Can be used to fetch search results and format them."
    spec.author = "BrowserMedia" 
    spec.email = "github@browsermedia.com" 
    spec.homepage = "http://github.com/browsermedia/bcms_google_mini_search" 
    spec.files = Dir["app/**/*"]  
    spec.files += Dir["lib/bcms_google_mini_search.rb"]
    spec.files += Dir["lib/bcms_google_mini_search/*"]
    spec.files -= Dir["lib/tasks/build_gem.rake"]
    spec.files += Dir["rails/init.rb"]
    spec.has_rdoc = true
    spec.extra_rdoc_files = ["README.markdown"]
  end
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

Jeweler::GemcutterTasks.new