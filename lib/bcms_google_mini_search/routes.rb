module Cms::Routes
  def routes_for_bcms_google_mini_search
    namespace(:cms) do |cms|
      #cms.content_blocks :google_mini_searches
    end  
  end
end
