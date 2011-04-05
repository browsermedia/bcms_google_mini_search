class GoogleMiniSearchEnginePortlet < Portlet

  enable_template_editor true

  def render
    @site = params[:site]
    @start = params[:start] ? params[:start].to_i : 0
    options = {:start => @start, :portlet => self, :site=>@site, :sort=>params[:sort]}
    query_string = params[:query]

    @results = SearchResult.find(query_string, options.clone) # Need to clone, so that :portlet isn't removed for the 2nd call.

    # This is temporary, while the API is being reworked. Ideally, the search results would contain a reference
    # to the query, so that two X calls isn't needed.
    @query = SearchResult.create_query(query_string, options.clone)

    if narrow_your_search?
      @appliance = SearchResult.new_gsa(self)
      @suggested_queries = @appliance.find_narrow_search_results(query_string)
    end
  end

  # Handles the fact that all portlet attributes, including checkboxes like enable_your_search are stored as strings.
  def narrow_your_search?
    self.enable_narrow_your_search == "1"
  end

end