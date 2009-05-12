SPEC = Gem::Specification.new do |spec| 
  spec.name = "bcms_google_mini_search"
  spec.rubyforge_project = spec.name
  spec.version = "1.0.0"
  spec.summary = "A Google Mini Search Module for BrowserCMS"
  spec.author = "BrowserMedia" 
  spec.email = "github@browsermedia.com" 
  spec.homepage = "http://www.browsercms.org" 
  spec.files += Dir["app/**/*"]  
  spec.files += Dir["lib/bcms_google_mini_search.rb"]
  spec.files += Dir["lib/bcms_google_mini_search/*"]
  spec.files += Dir["rails/init.rb"]
  spec.has_rdoc = true
  spec.extra_rdoc_files = ["README.markdown"]
end
