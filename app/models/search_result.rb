class SearchResult

  attr_accessor :number, :title, :url, :description, :size

  #
  # Queries google mini by a specific URL to find all the results. Converts XML results to
  # a paging results of Search Results.
  #
  def self.find(query, options={})
    xml_doc = fetch_xml_doc(query, options)
    results = parse_xml(xml_doc, options)
    results.query = query
    portlet = find_search_engine_portlet(options)
    results.path = portlet.path 
    results
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
      result = SearchResult.new
      result.number = ele.attributes["N"]
      result.title = ele.elements["T"].text
      result.url = ele.elements["U"].text
      result.description = ele.elements["S"].text
      result.size = ele.elements["HAS/C"].attributes["SZ"]

      results << result
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


  def self.build_mini_url(options, query)
    portlet = find_search_engine_portlet(options)
    encoded_query = CGI::escape(query)
    # encoded_query = query
    url = "#{portlet.service_url}/search?q=#{encoded_query}&output=xml_no_dtd&client=#{portlet.front_end_name}&site=#{portlet.collection_name}&filter=0"
    if options[:start]
      url = url + "&start=#{options[:start]}"
    end
    return url    
  end

  def self.find_search_engine_portlet(options)
    portlet = GoogleMiniSearchEnginePortlet.new
    if options[:portlet]
      portlet = options[:portlet]
    end
    portlet
  end

  # Fetches the xml response from the google mini server.
  def self.fetch_xml_doc(query, options={})
    # Turns off automatic results filter (filter=0), which when set to 1, allows mini to reduces the # of similar/duplicate results,
    # but makes it hard to determine the total # of results.
    url = build_mini_url(options, query)
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

    def path
      @path ? @path : "/search/search-results"
    end


    def next_page?
      next_start < results_count      
    end

    def previous_page?
      previous_start >= 0 && num_pages > 1
    end

    def pages
      if num_pages > 1
        return (1..num_pages)
      end
      []
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