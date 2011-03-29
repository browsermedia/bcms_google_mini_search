class SearchResult


  #
  # Queries google mini by a specific URL to find all the results. Converts XML results to
  # a paging results of Search Results.
  #
  def self.find(query, options={})
    return QueryResult.new unless query
    xml_doc = fetch_xml_doc(query, options)
    results = parse_xml(xml_doc, options)
    results.query = query
    portlet = find_search_engine_portlet(options)
    results.path = portlet.path 
    results
  end

  def self.create_query(query, options={})
    Rails.logger.warn "create_query called"
    opts = options.clone
    normalize_query_options(opts)
    opts[:query] = query
    opts[:engine] = GSA::Engine.new({:host => opts[:host]})
    Rails.logger.warn "Host is #{opts[:host]}"
    Rails.logger.warn "Engine's host is: #{opts[:engine].host}"
    GSA::Query.new(opts)
  end

  def self.parse_results_count(xml_doc)
    root = xml_doc.root
    count = root.elements["RES/M"]
    count ? count.text.to_i : 0
  end

  def self.parse_hits(xml_doc)
    root = xml_doc.root
    results = []
    xml_doc.elements.each('GSP/RES/R') do |ele|
      results << GSA::Result.new(ele)
    end
    results
  end

  def self.parse_xml(xml_doc, options={})
    hits = parse_hits(xml_doc)
    results = QueryResult.new(hits)
    results.key_matches= parse_key_matches(xml_doc)
    results.synonyms = parse_synonyms(xml_doc, results)
    results.results_count = parse_results_count(xml_doc)
    results.num_pages = calculate_results_pages(results.results_count)
    results.start = options[:start] ? options[:start] : 0
    results
  end



  def self.calculate_results_pages(results_count)
    num_pages = results_count / 10
    num_pages = num_pages + 1 if results_count % 10 > 0
    num_pages
  end

  # Construct a query url for the GSA.
  #
  # @param [String] query
  # @param [Hash] options
  # @option :host
  # @option :start
  # @option :front_end
  # @option :collection
  # @option :sort
  # @option :as_xml [Boolean] Determines if the results are returned as xml or html. Default to false.
  def self.query_url(query, options)
    options[:as_xml] = true if options[:as_xml].nil?

    encoded_query = CGI::escape(query)

    # encoded_query = query
    url = "#{options[:host]}/search?q=#{encoded_query}&output=xml_no_dtd&client=#{options[:front_end]}&site=#{options[:collection]}&filter=0"
    if options[:start]
      url = url + "&start=#{options[:start]}"
    end

    if options[:sort]
      url += "&sort=#{CGI::escape(options[:sort])}"
    end

    unless options[:as_xml]
      url += "&proxystylesheet=#{options[:front_end]}"
    end
    return url
  end

  def self.build_mini_url(options, query)
    normalize_query_options(options)
    return query_url(query, options)
  end

  def self.normalize_query_options(options)
    portlet = find_search_engine_portlet(options)
    Rails.logger.warn "Portlet found: #{portlet.inspect}"
    options[:front_end] = portlet.front_end_name
    options[:collection] = portlet.collection_name
    options[:host] = portlet.service_url

    options[:collection] = options.delete(:site) if options[:site]
  end

  def self.find_search_engine_portlet(options)
    portlet = GoogleMiniSearchEnginePortlet.new
    if options[:portlet]
      portlet = options.delete(:portlet)
    end
    portlet
  end

  # Fetches the xml response from the google mini server.
  def self.fetch_xml_doc(query, options={})
    # Turns off automatic results filter (filter=0), which when set to 1, allows mini to reduces the # of similar/duplicate results,
    # but makes it hard to determine the total # of results.
    url = build_mini_url(options, query)
    Rails.logger.debug "Querying GSA/Mini @ #{url}"
    response = Net::HTTP.get(URI.parse(url))
    xml_doc = REXML::Document.new(response)
    return xml_doc
  end

  def self.parse_key_matches(xml_doc)
    matches = []
    xml_doc.elements.each('GSP/GM') do |ele|
      key_match = KeyMatch.new
      key_match.url = ele.elements["GL"].text
      key_match.title = ele.elements["GD"].text
      matches << key_match
    end
    matches
  end

  def self.parse_synonyms(xml_doc, query_result)
    synonyms = []
    xml_doc.elements.each('GSP/Synonyms/OneSynonym') do |ele|
      synonym = Synonym.new
      synonym.query = ele.attributes["q"]
      synonym.label = ele.text
      synonym.query_result = query_result
      synonyms << synonym
    end
    synonyms
  end
  # Represents the entire result of the query
  class QueryResult < Array

    attr_accessor :results_count, :num_pages, :current_page, :start, :query, :pages, :key_matches, :synonyms
    attr_writer :path

    # For what these codes mean, see http://code.google.com/apis/searchappliance/documentation/46/xml_reference.html#request_sort
    SORT_BY_DATE_PARAM = "date:D:S:d1"
    SORT_BY_RELEVANCE_PARAM = "date:D:L:d1"

    def initialize(array=[])
      # Need to set defaults so an empty result set works.
      self.start = 0
      self.results_count=0
      self.key_matches = []
      self.synonyms = []
      self.num_pages = 1
      super(array)

    end
    
    def path
      @path ? @path : "/search/search-results"
    end


    def next_page?
      next_start < results_count      
    end

    def previous_page?
      previous_start >= 0 && num_pages > 1
    end

    # Returns a range of pages that should appear in the pager control. This is design to mimic GSA's pager control,
    # which will show up to 20 pages at a time, based on the 'range' of pages around the current page.
    #
    # i.e. on page 12:  < 2 3 4 5 6 7 8 9 10 11 _12_ 13 14 15 16 17 18 19 20 21 22 >
    def pages
      return [] if num_pages <= 1
      first_page = current_page - 10 > 1 ? current_page - 10 : 1
      last_page = current_page + 9 > num_pages ? num_pages : current_page + 9
      (first_page..last_page)
    end

    def next_start
      start + 10
    end

    def previous_start
      start - 10
    end
    
    def current_page?(page_num)
      (page_num * 10 - 10 == start )
    end

    def current_page
      return page = start / 10 + 1 if start
      1
    end

    # Determines the current Query is sorting by date.
    #
    # @param [Hash] params The query parameter from the search page. (same as Rails params)
    def sorting_by_date?(params)
      params[:sort] == SearchResult::QueryResult::SORT_BY_DATE_PARAM
    end
    # Return the path to sort the current search results by date.
    #
    # Based on http://code.google.com/apis/searchappliance/documentation/46/xml_reference.html#request_sort
    def sort_by_date_path
      "#{path}?query=#{query}&sort=#{SORT_BY_DATE_PARAM}"
    end

    # Returns the path to sort the current results by relevance (inverse of sort_by_date_path).
    def sort_by_relevance_path
      "#{path}?query=#{query}&sort=#{SORT_BY_RELEVANCE_PARAM}"
    end

    def next_page_path
      "#{path}?query=#{query}&start=#{next_start}"
    end

    def previous_page_path
      "#{path}?query=#{query}&start=#{previous_start}"
    end

    def page_path(page_num)
      "#{path}?query=#{query}&start=#{page_num * 10 - 10}"
    end

    def key_matches?
      !key_matches.empty?
    end

    def synonyms?
      !synonyms.empty?
    end
  end

  # Sometimes refered to as 'Featured Links', though the GSA UI uses the KeyMatch
  class KeyMatch
    attr_accessor :url, :title
  end

  # AKA Related Query in Google UI
  class Synonym
    attr_accessor :query, :label, :query_result

    # Return the url that should be
    def url
      "#{query_result.path}?query=#{query}"
    end
  end


end