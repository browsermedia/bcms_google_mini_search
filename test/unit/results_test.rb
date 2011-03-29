require "test_helper"

class GSA::ApplianceTest < ActiveSupport::TestCase

  test "Create Engine" do
    app = GSA::Engine.new
    app.host = "http://example.com"
    assert_equal "http://example.com", app.host
    assert_equal 8080, app.port
    assert_equal "/search", app.path
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
    expected_url = "http://mini.someurl.com/search?q=cache%3Asomething&output=xml_no_dtd&client=FRONT_END&site=COLLECT&filter=0&proxystylesheet=FRONT_END"
    assert_equal expected_url, @result.cached_document_url(@query)
  end
end