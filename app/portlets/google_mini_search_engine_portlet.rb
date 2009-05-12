class GoogleMiniSearchEnginePortlet < Portlet
    
  def render
    @query = params[:query]
    @start = params[:start] ? params[:start].to_i : 0
    @results = SearchResult.find(@query, {:start => @start, :portlet => @portlet})
  end
    
end