require File.join(File.dirname(__FILE__), '/../test_helper')

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

  test "Behavior of ranges" do
    c = 0
    (1..4).each_with_index do |i, count|
      assert_equal count + 1, i
      c = count
    end
    assert_equal 3, c
  end

  test "current_page should check to see if the current page matches" do
    results = SearchResult::QueryResult.new
    results.start = 0

    assert_equal true, results.current_page?(1)
    assert_equal false, results.current_page?(2)
    assert_equal false, results.current_page?(3)
    assert_equal false, results.current_page?(4)

  end

  test "Path to next page" do
    results = SearchResult::QueryResult.new
    results.start = 0
    results.path = "/search/search-results"
    results.query = "X"

    assert_equal "/search/search-results?query=X&start=10", results.next_page_path
  end

  test "Path to previous page" do
    results = SearchResult::QueryResult.new
    results.start = 20
    results.path = "/search/search-results"
    results.query = "X"

    assert_equal "/search/search-results?query=X&start=10", results.previous_page_path
  end

  test "Sets path to default search-results" do
    results = SearchResult::QueryResult.new
    assert_equal "/search/search-results", results.path
  end

  test "Setting path overrides the defaults" do
    results = SearchResult::QueryResult.new
    results.path = "/other"
    assert_equal "/other", results.path
  end

  test "page_path" do
    results = SearchResult::QueryResult.new
    results.query = "X"

    assert_equal "/search/search-results?query=X&start=0", results.page_path(1)
    assert_equal "/search/search-results?query=X&start=10", results.page_path(2)
    assert_equal "/search/search-results?query=X&start=20", results.page_path(3)
    assert_equal "/search/search-results?query=X&start=30", results.page_path(4)

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

    url = SearchResult.build_mini_url({:portlet => portlet}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0", url

    url = SearchResult.build_mini_url({:portlet => portlet, :start=>100}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0&start=100", url

  end

  test "Explicitly passing a collection in will query with that rather than a default collection" do
    portlet = GoogleMiniSearchEnginePortlet.new(
            :name=>"Engine", :path => "/engine", :service_url => "http://mini.someurl.com",
            :collection_name => "COLLECT", :front_end_name => "FRONT_END")

    url = SearchResult.build_mini_url({:portlet => portlet, :site=>"ANOTHER_COLLECTION"}, "STUFF")
    assert_equal "http://mini.someurl.com/search?q=STUFF&output=xml_no_dtd&client=FRONT_END&site=ANOTHER_COLLECTION&filter=0", url
  end

  test "Handles multiword queries" do
    url = SearchResult.build_mini_url({}, "One Two")
    assert_equal "/search?q=One+Two&output=xml_no_dtd&client=&site=&filter=0", url
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
