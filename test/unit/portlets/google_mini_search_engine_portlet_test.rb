require File.join(File.dirname(__FILE__), '/../../test_helper')

class GoogleMiniSearchEngineTest < ActiveSupport::TestCase

  def setup
    @portlet = GoogleMiniSearchEnginePortlet.new(:name=>"Engine", :path => "/engine")
  end

  test "Should be able to create new instance of a portlet" do
    assert GoogleMiniSearchEnginePortlet.create!(:name => "New Portlet")
  end

  test "Path attribute can be set in constructor" do
    portlet = GoogleMiniSearchEnginePortlet.create!(:name=>"Engine", :path => "/engine")
    assert_equal "/engine", portlet.path
  end

  test "Sort params" do
    params = {:start => 10, :query => "X", :site=>'default_collection', :sort=>"date:D:S:d1"}
    @portlet.expects('params').returns(params).at_least_once
    SearchResult.expects(:find).with("X", {:start => 10, :portlet => nil, :site=>'default_collection', :sort=>"date:D:S:d1"})

    @portlet.render
  end
  

end