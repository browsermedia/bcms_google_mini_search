require "test_helper"

class GSA::ApplianceTest < ActiveSupport::TestCase

  test "Create Engine" do
    app = GSA::Engine.new
    app.host = "http://example.com"
    assert_equal "http://example.com", app.host
    assert_equal 8080, app.port
    assert_equal "/search", app.path
  end

  test "Create from options" do
    app = GSA::Engine.new({:host=>"http://example.com", :front_end=>"F", :collection=>"C"})
    assert_equal "http://example.com", app.host
    assert_equal "F", app.default_front_end
    assert_equal "C", app.default_collection
  end

  test "options_for_query" do
    options = {:host=>"http://example.com", :front_end=>"F", :collection=>"C"}
    app = GSA::Engine.new(options)
    assert_equal options, app.options_for_query
  end
end

class SuggestedQueries < ActiveSupport::TestCase

  def setup
    @cluster_xml = <<XML
<toplevel>
  <Response>
    <algorithm data="Concepts"/>
    <t_cluster int="95"/>
    <cluster>
      <gcluster>
        <label data="label 0"/>
      </gcluster>
      <gcluster>
        <label data="label 1"/>
      </gcluster>
      <gcluster>
        <label data="label 2"/>
      </gcluster>
      <gcluster>
        <label data="label 3"/>
      </gcluster>
      <gcluster>
        <label data="label 4"/>
      </gcluster>
      <gcluster>
        <label data="label 5"/>
      </gcluster>
      <gcluster>
        <label data="label 6"/>
      </gcluster>
      <gcluster>
        <label data="label 7"/>
      </gcluster>
      <gcluster>
        <label data="label 8"/>
      </gcluster>
      <gcluster>
        <label data="label 9"/>
      </gcluster>
    </cluster>
  </Response>
</toplevel>
XML

    @app = GSA::Appliance.new(:host=>"http://example.com", :collection=>"My_Collection", :front_end=>"My_Front")

  end

  test "parse results" do
    suggested_queries = GSA::SuggestedQueries.new(@cluster_xml)
    assert_equal 10, suggested_queries.size
    assert_equal "label 0", suggested_queries[0].query
    assert_equal "label 9", suggested_queries[9].query
  end

  test "Google Search Appliances should generate the URL for Dynamic Results Clustering" do
    expected = "http://example.com/cluster?coutput=xml&q=TEST&site=My_Collection&client=My_Front&output=xml_no_dtd&oe=UTF-8&ie=UTF-8"
    assert_equal expected, @app.send(:narrow_search_results_url, "TEST")
  end

  test "URLs will escape queries" do
    expected = "http://example.com/cluster?coutput=xml&q=TWO+WORDS&site=My_Collection&client=My_Front&output=xml_no_dtd&oe=UTF-8&ie=UTF-8"
    assert_equal expected, @app.send(:narrow_search_results_url, "TWO WORDS")
  end

  test "find narrowed search results" do
    @app.expects(:narrow_search_results_url).with("TEST").returns("EXPECTED URL")
    SearchResult.expects(:fetch_document).with("EXPECTED URL").returns("XML Content")
    expected_suggestions = mock()
    GSA::SuggestedQueries.expects(:new).with("XML Content").returns(expected_suggestions)

    assert_equal expected_suggestions, @app.find_narrow_search_results("TEST")

  end

  test "each_with_index" do
    suggestions = GSA::SuggestedQueries.new(@cluster_xml)
    count = 0
    suggestions.each_with_index do |s, i|
      assert_not_nil s
      assert_not_nil i
      count += 1
    end
    assert_equal suggestions.size, count
  end

  test "each" do
    suggestions = GSA::SuggestedQueries.new(@cluster_xml)
    count = 0
    suggestions.each do |s|
      assert_not_nil s
      count += 1
    end
    assert_equal suggestions.size, count
  end

  test "A nil query should return an empty set of Suggested Queries" do
    r = @app.find_narrow_search_results(nil)
    assert_equal 0, r.size
  end
end

class ResultsTest < ActiveSupport::TestCase

  def setup
    @results = GSA::Results.new
    @results.query = "QUERY"
    @result = GSA::Result.new
    @result.results = @results

    @engine = GSA::Engine.new(:host=>"http://mini.someurl.com")
    @query = GSA::Query.new(:engine=>@engine, :collection=>"COLLECT", :front_end=>"FRONT_END")
  end

  test "Handles missing elements that we kinda expect to be there" do
    xml = <<XML
  <R N="1">
    <HAS>
      <C SZ="1k" CID="Ax1j5"/>
    </HAS>
  </R>
XML
    xml_doc = REXML::Document.new(xml)
    result = GSA::Result.new(xml_doc.elements.first)
    assert_nil result.url
    assert_nil result.title
    assert_nil result.description
  end
  
  test "Create result from xml" do
    xml = <<XML
  <R N="1">
    <U>http://someurl.com</U>
    <T>TITLE</T>
    <S>BLURB</S>
    <HAS>
      <C SZ="1k" CID="Ax1j5"/>
    </HAS>
  </R>
XML
    xml_doc = REXML::Document.new(xml)
    result = GSA::Result.new(xml_doc.elements.first)
    assert_equal "http://someurl.com", result.url
    assert_equal "TITLE", result.title
    assert_equal "BLURB", result.description
    assert_equal "1k", result.size
    assert_equal "1", result.number
    assert_equal "Ax1j5", result.cache_id
  end

  test "cached_document_param" do
    @result.cache_id = "A2B"
    @result.url = "http://example.com"

    assert_equal "cache:A2B:http://example.com+QUERY", @result.cached_document_param
  end

  test "cached_document_param with no result attached" do
    @result.results = nil
    @result.cache_id = "A2B"
    @result.url = "http://example.com"

    assert_equal "cache:A2B:http://example.com", @result.cached_document_param
  end

  test "cached_document_url" do
    @result.expects(:cached_document_param).returns("cache:something")
    expected_url = "http://mini.someurl.com/search?q=cache%3Asomething&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0&proxystylesheet=FRONT_END&oe=UTF-8&ie=UTF-8"
    assert_equal expected_url, @result.cached_document_url(@query)
  end
end