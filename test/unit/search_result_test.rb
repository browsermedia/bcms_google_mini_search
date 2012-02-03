require 'test_helper'


class SearchResultTest < ActiveSupport::TestCase

  def setup
    @xml_string =  <<EOF
      <GSP>
        <RES>
          <M>2</M>
          <R N="1">
            <U>http://someurl.com</U>
            <T>TITLE</T>
            <S>BLURB</S>
            <HAS>
              <C SZ="1k" />
            </HAS>
          </R>
          <R N="2">
            <U>http://someurl2.com</U>
            <T>TITLE 2</T>
            <S>BLURB 2</S>
            <HAS>
              <C SZ="2k"/>
            </HAS>
          </R>
        </RES>
      </GSP>
EOF
    @xml_doc =  REXML::Document.new @xml_string

    @large_results_set = <<EOF
      <GSP>
        <RES>
          <M>35</M>
          <R N="1">
            <U>http://someurl.com</U>
            <T>TITLE</T>
            <S>BLURB</S>
            <HAS>
              <C SZ="1k" />
            </HAS>
          </R>
          <R N="2">
            <U>http://someurl2.com</U>
            <T>TITLE 2</T>
            <S>BLURB 2</S>
            <HAS>
              <C SZ="2k"/>
            </HAS>
          </R>
        </RES>
      </GSP>
EOF
    @large_xml_doc = REXML::Document.new(@large_results_set)
    
  end

  test "fetch_xml_doc should download and parse the xml results from the GSA" do
    SearchResult.expects(:create_url_for_query).returns("http://example.com")
    SearchResult.expects(:fetch_document).with("http://example.com").returns(nil)
    REXML::Document.expects(:new).with(nil).returns("EXPECTED_RESULTS")
    assert_equal "EXPECTED_RESULTS", SearchResult.fetch_xml_doc("")
  end

  test "Parse result count from google mini results xml." do

    xml =  <<EOF
      <GSP>
        <RES>
          <M>35</M>
        </RES>
      </GSP>
EOF
    empty_doc = REXML::Document.new xml
    assert_equal 35, SearchResult.parse_results_count(empty_doc)
    assert_equal 35, SearchResult.parse_xml(empty_doc).results_count
    assert_equal 4, SearchResult.parse_xml(empty_doc).num_pages

  end

  test "Default result count is zero." do

    xml =  <<EOF
      <GSP>
        <RES>
        </RES>
      </GSP>
EOF
    empty_doc = REXML::Document.new xml
    assert_equal 0, SearchResult.parse_results_count(empty_doc)

  end

  test "Empty xml gives empty results" do
    xml =  <<EOF
      <GSP>
        <RES>
        </RES>
      </GSP>
EOF
    empty_doc = REXML::Document.new xml
    SearchResult.expects(:fetch_xml_doc).with("therapy", {}).returns(empty_doc)

    assert_equal [], SearchResult.find("therapy", {})
  end

  test "Parse result set" do

    results = SearchResult.parse_hits(@xml_doc)
    assert_equal 2, results.size

    assert_equal "1", results[0].number
    assert_equal "http://someurl.com", results[0].url
    assert_equal "TITLE", results[0].title
    assert_equal "BLURB", results[0].description
    assert_equal "1k", results[0].size

    assert_equal "2", results[1].number
    assert_equal "http://someurl2.com", results[1].url
    assert_equal "TITLE 2", results[1].title
    assert_equal "BLURB 2", results[1].description
    assert_equal "2k", results[1].size
  end


  test "Calculates the results pages" do
    assert_equal 1, SearchResult.calculate_results_pages(9)
    assert_equal 1, SearchResult.calculate_results_pages(10)
    assert_equal 2, SearchResult.calculate_results_pages(19)
    assert_equal 2, SearchResult.calculate_results_pages(20)
    assert_equal 3, SearchResult.calculate_results_pages(21)
    assert_equal 4, SearchResult.calculate_results_pages(40)
    assert_equal 0, SearchResult.calculate_results_pages(0)

  end

  test "Calculates current page based on total results and start" do
    results = SearchResult::QueryResult.new
    results.start = 0
    assert_equal 1, results.current_page

    results.start = 10
    assert_equal 2, results.current_page

    results.start = 20
    assert_equal 3, results.current_page

    results.start = 30
    assert_equal 4, results.current_page
  end

  test "Next start" do
    r = SearchResult::QueryResult.new
    r.start = 0
    assert_equal 10, r.next_start
    r.start = 10
    assert_equal 20, r.next_start
    r.start = 20
    assert_equal 30, r.next_start
  end

  test "Find results should return a paging list of documents with no start" do
    SearchResult.expects(:fetch_xml_doc).with("therapy", {}).returns(@large_xml_doc)

    results = SearchResult.find("therapy")
    assert_equal "therapy", results.query
    assert_equal 35, results.results_count
    assert_equal 4, results.num_pages
    assert_equal 0, results.start
    assert_equal 2, results.size
    assert_equal 1, results.current_page
    assert_equal 10, results.next_start
    assert results.next_page?
    assert_equal -10, results.previous_start
    assert_equal false, results.previous_page?
    assert_equal (1..4), results.pages

  end


  test "Find results starts on page 2, if a start is specified" do
    SearchResult.expects(:fetch_xml_doc).with("therapy", :start=>10).returns(@large_xml_doc)

    results = SearchResult.find("therapy", :start => 10)
    assert_equal 35, results.results_count
    assert_equal 4, results.num_pages
    assert_equal 10, results.start
    assert_equal 2, results.size
    assert_equal 2, results.current_page
    assert_equal 20, results.next_start
    assert results.next_page?
    assert_equal 0, results.previous_start
    assert_equal true, results.previous_page?
  end

  test "No next start when on the last page" do
    SearchResult.expects(:fetch_xml_doc).with("therapy", {:start => 30}).returns(@large_xml_doc)

    results = SearchResult.find("therapy", :start => 30)
    assert_equal 40, results.next_start
    assert_equal false, results.next_page?
    assert_equal 20, results.previous_start
    assert_equal true, results.previous_page?
  end

  test "Should be no previous or next for a single page of results" do
    SearchResult.expects(:fetch_xml_doc).with("therapy", {}).returns(@xml_doc)

    results = SearchResult.find("therapy")
    assert_equal false, results.next_page?
    assert_equal false, results.previous_page?
    assert_equal [], results.pages
  end



  test "current_page should check to see if the current page matches" do
    results = SearchResult::QueryResult.new
    results.start = 0

    assert_equal true, results.current_page?(1)
    assert_equal false, results.current_page?(2)
    assert_equal false, results.current_page?(3)
    assert_equal false, results.current_page?(4)

  end


  test "Portlet attributes are used to look up path" do
    portlet = GoogleMiniSearchEnginePortlet.new(:name=>"Engine", :path => "/engine")
    SearchResult.expects(:fetch_xml_doc).with("therapy", {:portlet=> portlet}).returns(@xml_doc)

    results = SearchResult.find("therapy", {:portlet=> portlet})

    assert_equal "/engine", results.path
  end

  test "Default path is used if no portlet specified" do
    SearchResult.expects(:fetch_xml_doc).with("therapy", {}).returns(@xml_doc)
    results = SearchResult.find("therapy", {})
    assert_equal "/search/search-results", results.path
  end

  test "Uses service URL from portlet" do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")

    url = SearchResult.create_url_for_query({:portlet => portlet}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0&oe=UTF-8&ie=UTF-8", url

    url = SearchResult.create_url_for_query({:portlet => portlet, :start=>100}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0&start=100&oe=UTF-8&ie=UTF-8", url

  end

  test "Create Engine and Query from portlet attributes" do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")

    query = SearchResult.create_query("therapy", {:portlet=>portlet})
    assert_equal "http://mini.someurl.com", query.engine.host
    assert_equal portlet.front_end_name, query.front_end
    assert_equal portlet.collection_name, query.collection
    assert_equal "therapy", query.query
  end

  test "should look up options from portlet and add to hash" do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")
    options = {:portlet=>portlet}
    SearchResult.normalize_query_options(options)

    assert_equal "FRONT_END", options[:front_end]
    assert_equal "COLLECT", options[:collection]
    assert_equal "http://mini.someurl.com", options[:host]
    assert_equal nil, options[:portlet]
  end

  test "Create an appliance from attributes in the portlet." do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")

    gsa = SearchResult.new_gsa(portlet)
    assert_equal "http://mini.someurl.com", gsa.host
    assert_equal "FRONT_END", gsa.default_front_end
    assert_equal "COLLECT", gsa.default_collection
  end

  test "Explicitly passing a collection in will query with that rather than a default collection" do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")

    url = SearchResult.create_url_for_query({:portlet => portlet, :site=>"ANOTHER_COLLECTION"}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=ANOTHER_COLLECTION&filter=0&oe=UTF-8&ie=UTF-8", url
  end

  test "Handles multiword queries" do
    url = SearchResult.create_url_for_query({}, "One Two")
    assert_equal "/search?q=One+Two&output=xml_no_dtd&client=&site=&filter=0&oe=UTF-8&ie=UTF-8", url
  end

  test "sort is added to google mini query" do
    url = SearchResult.create_url_for_query({:sort=>"XYZ"}, "STUFF")
    assert_equal "/search?q=STUFF&output=xml_no_dtd&client=&site=&filter=0&sort=XYZ&oe=UTF-8&ie=UTF-8", url
  end

  test "sort params are escaped" do
    url = SearchResult.create_url_for_query({:sort=>"date:D:S:d1"}, "STUFF")
    assert_equal "/search?q=STUFF&output=xml_no_dtd&client=&site=&filter=0&sort=date%3AD%3AS%3Ad1&oe=UTF-8&ie=UTF-8", url
  end

  test "Handles keymatches in results" do
    @xml_with_keymatches = <<XML
    <GSP>
        <GM>
          <GL>http://url1.org</GL>
          <GD>URL 1</GD>
        </GM>
        <GM>
          <GL>http://url2.org</GL>
          <GD>URL 2</GD>
        </GM>
        <RES>
          <M>35</M>
          <R N="1">
            <U>http://someurl.com</U>
            <T>TITLE</T>
            <S>BLURB</S>
            <HAS>
              <C SZ="1k" />
            </HAS>
          </R>
          <R N="2">
            <U>http://someurl2.com</U>
            <T>TITLE 2</T>
            <S>BLURB 2</S>
            <HAS>
              <C SZ="2k"/>
            </HAS>
          </R>
        </RES>
      </GSP>
XML
    @results_with_keymatches =  REXML::Document.new @xml_with_keymatches

    result = SearchResult.parse_xml @results_with_keymatches

    assert_equal true, result.key_matches?
    assert_equal 2, result.key_matches.size
    assert_equal "http://url1.org", result.key_matches[0].url
    assert_equal "URL 1", result.key_matches[0].title
    assert_equal "http://url2.org", result.key_matches[1].url
    assert_equal "URL 2", result.key_matches[1].title
  end

  test "Handles results with no keymatches" do
    result = SearchResult.parse_xml @xml_doc
    assert_equal false, result.key_matches?
  end

  test "Handle Synonyms / Related Queries" do
    xml_with_synonyms = <<XML
    <GSP>
        <Synonyms>
          <OneSynonym q="Query 1">Label 1</OneSynonym>
          <OneSynonym q="Query 2">Label 2</OneSynonym>
        </Synonyms>
        <RES>
          <M>35</M>
          <R N="1">
            <U>http://someurl.com</U>
            <T>TITLE</T>
            <S>BLURB</S>
            <HAS>
              <C SZ="1k" />
            </HAS>
          </R>
          <R N="2">
            <U>http://someurl2.com</U>
            <T>TITLE 2</T>
            <S>BLURB 2</S>
            <HAS>
              <C SZ="2k"/>
            </HAS>
          </R>
        </RES>
      </GSP>
XML
    xml_doc_with_synonyms =  REXML::Document.new xml_with_synonyms

    result = SearchResult.parse_xml xml_doc_with_synonyms

    result.expects(:path).returns("/search").twice
    assert_equal true, result.synonyms?
    assert_equal 2, result.synonyms.size
    assert_equal "Label 1", result.synonyms[0].label
    assert_equal "Query 1", result.synonyms[0].query
    assert_equal "/search?query=Query 1", result.synonyms[0].url
    assert_equal "Label 2", result.synonyms[1].label
    assert_equal "Query 2", result.synonyms[1].query
    assert_equal "/search?query=Query 2", result.synonyms[1].url

  end

  test "Handles results with no Synonyms" do
    result = SearchResult.parse_xml @xml_doc
    assert_equal false, result.synonyms?                                       
  end

  test "Calculate URL for Related Queries/Synonyms" do
    syn = SearchResult::Synonym.new
    syn.query = "Testing"
    mock_result = mock()
    mock_result.expects(:path).returns("/random")
    syn.query_result = mock_result
    assert_equal "/random?query=Testing", syn.url
  end

  test "No query = empty results" do
    result = SearchResult.find(nil)
    assert_equal 0, result.size
    assert_equal 0, result.start
    assert_equal false, result.next_page?
    assert_equal false, result.previous_page?
    assert_equal false, result.key_matches?
    assert_equal false, result.synonyms?
    assert_equal [], result.pages
  end
  
  test "Search results for PDF's that have no size" do
    pdf_results = <<EOF
      <GSP>
        <RES>
          <M>35</M>
          <R N="1">
            <U>http://someurl.com</U>
            <T>TITLE</T>
            <S>BLURB</S>
            <HAS>
              <C SZ="1k" />
            </HAS>
          </R>
          <R N="2">
            <U>http://someurl2.com</U>
            <T>TITLE 2</T>
            <S>BLURB 2</S>
            <HAS>
              <L/>
            </HAS>
          </R>
        </RES>
      </GSP>
EOF
      xml_doc = REXML::Document.new(pdf_results)
      results = SearchResult.parse_xml xml_doc
      assert_equal 2, results.size

      assert_equal "1", results[0].number
      assert_equal "http://someurl.com", results[0].url
      assert_equal "TITLE", results[0].title
      assert_equal "BLURB", results[0].description
      assert_equal "1k", results[0].size

      assert_equal "2", results[1].number
      assert_equal "http://someurl2.com", results[1].url
      assert_equal "TITLE 2", results[1].title
      assert_equal "BLURB 2", results[1].description
      assert_equal "", results[1].size
  end

end

class SearchPathsTest < ActiveSupport::TestCase

  def setup
    @results = SearchResult::QueryResult.new
    @results.start = 0
    @results.path = "/search/search-results"
    @results.query = "X"
  end

  test "path_for" do
    assert_equal "/search/search-results?query=Y", @results.path_for("Y")
  end
  
  test "sort by date" do
    assert_equal "#{@results.path}?query=#{@results.query}&sort=#{SearchResult::QueryResult::SORT_BY_DATE_PARAM}", @results.sort_by_date_path
  end

  test "sort by relevance" do
    assert  @results.sort_by_relevance_path != @results.sort_by_date_path, "Paths should not be the same."
    assert_equal "#{@results.path}?query=#{@results.query}&sort=#{SearchResult::QueryResult::SORT_BY_RELEVANCE_PARAM}", @results.sort_by_relevance_path
  end

  test "Path to next page" do
    assert_equal "/search/search-results?query=X&start=10", @results.next_page_path
  end

  test "Path to previous page" do
    @results.start = 20
    assert_equal "/search/search-results?query=X&start=10", @results.previous_page_path
  end

  test "Sets path to default search-results" do
    assert_equal "/search/search-results", @results.path
  end

  test "Setting path overrides the defaults" do
    @results.path = "/other"
    assert_equal "/other", @results.path
  end

  test "page_path" do
    assert_equal "/search/search-results?query=X&start=0", @results.page_path(1)
    assert_equal "/search/search-results?query=X&start=10", @results.page_path(2)
    assert_equal "/search/search-results?query=X&start=20", @results.page_path(3)
    assert_equal "/search/search-results?query=X&start=30", @results.page_path(4)
  end

  test "sorting_by_date?" do
    assert_equal true, @results.sorting_by_date?({:sort=>SearchResult::QueryResult::SORT_BY_DATE_PARAM})
    assert_equal false, @results.sorting_by_date?({:sort=>SearchResult::QueryResult::SORT_BY_RELEVANCE_PARAM})
    assert_equal false, @results.sorting_by_date?({})
  end
end


class PagingTest < ActiveSupport::TestCase

  def setup
    @results = SearchResult::QueryResult.new
    and_the_max_number_pages_is 100
  end

  test "Behavior of Ruby Ranges" do
      c = 0
      (1..4).each_with_index do |i, count|
        assert_equal count + 1, i
        c = count
      end
      assert_equal 3, c
    end


  test "When on page 1, show links for pages 1 - 10" do
    when_current_page_is(1)
    assert_equal (1..10), @results.pages
  end

  test "When on page 11, show links for pages 1-20" do
    when_current_page_is(11)
    assert_equal (1..20), @results.pages
  end

  test "When on page 12, show links for pages 2-22" do
    when_current_page_is 12
    assert_equal (2..21), @results.pages
  end

  test "When less than 10 pages only show up to last page" do
    when_current_page_is 1
    and_the_max_number_pages_is 4

    assert_equal (1..4), @results.pages
  end

  test "When no results, should be empty set of pages." do
    when_current_page_is 1
    and_the_max_number_pages_is 0
    assert_equal [], @results.pages
  end

  test "With one page, return a single page." do
    when_current_page_is 1
    and_the_max_number_pages_is 1
    assert_equal [], @results.pages, "A single page of results needs no pager control"
  end

  private

  def and_the_max_number_pages_is(number)
    @results.expects(:num_pages).returns(number).times(0..5)
  end

  def when_current_page_is(current_page)
    @results.expects(:current_page).returns(current_page).times(0..5)
  end
end
