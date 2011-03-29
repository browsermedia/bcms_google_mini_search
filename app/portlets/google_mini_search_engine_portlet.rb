class GoogleMiniSearchEnginePortlet < Portlet

  enable_template_editor false
  
  def render
    @site = params[:site]
    @start = params[:start] ? params[:start].to_i : 0
    options = {:start => @start, :portlet => @portlet, :site=>@site, :sort=>params[:sort]}
    query_string = params[:query]

    @results = SearchResult.find(query_string, options.clone)  # Need to clone, so that :portlet isn't removed for the 2nd call.

    # This is temporary, while the API is being reworked. Ideally, the search results would contain a reference
    # to the query, so that two X calls isn't needed.
    @query = SearchResult.create_query(query_string, options)
  end


  actual = 'http://agasearch.browsermedia.com/search?q=cache:Mf5TO-oXhc4J:http://www.gastro.org/news/articles/2010/12/07/tests-between-colonoscopies-could-be-lifesaver-for-high-risk-patients&output=xml_no_dtd&client=testing-aga-3&site=default_collection&filter=0'
  expect = 'http://agasearch.browsermedia.com/search?q=cache:Mf5TO-oXhc4J:http://www.gastro.org/news/articles/2010/12/07/tests-between-colonoscopies-could-be-lifesaver-for-high-risk-patients+testing&site=All_AGA&client=testing-aga-3&output=xml_no_dtd&proxystylesheet=testing-aga-3&ie=UTF-8&access=p&oe=ISO-8859-1'

  exp_or = 'http://agasearch.browsermedia.com/search?q=cache:Mf5TO-oXhc4J:http://www.gastro.org/news/articles/2010/12/07/tests-between-colonoscopies-could-be-lifesaver-for-high-risk-patients+testing&site=All_AGA&client=testing-aga-3&output=xml_no_dtd&proxystylesheet=testing-aga-3&ie=UTF-8&access=p&oe=ISO-8859-1'
end