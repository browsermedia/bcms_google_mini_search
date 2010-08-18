class GoogleMiniSearchEnginePortlet < Portlet

  enable_template_editor true
  
  def render
    @query = params[:query]
    @site = params[:site]
    @start = params[:start] ? params[:start].to_i : 0
    @results = SearchResult.find(@query, {:start => @start, :portlet => @portlet, :site=>@site})
  end
    
end