require 'test_helper'

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

  test "Determine if Narrow Your Search is enabled?" do
    @portlet.enable_narrow_your_search = "1"
    assert_equal true, @portlet.narrow_your_search?

    @portlet.enable_narrow_your_search = "0"
    assert_equal false, @portlet.narrow_your_search?

    @portlet.enable_narrow_your_search = ""
    assert_equal false, @portlet.narrow_your_search?

    @portlet.enable_narrow_your_search = nil
    assert_equal false, @portlet.narrow_your_search?
  end


end

class RenderTest < ActiveSupport::TestCase
  def setup
    @portlet = GoogleMiniSearchEnginePortlet.new(:name=>"Engine", :path => "/engine")
    @params = {:start => 10, :query => "X", :site=>'default_collection', :sort=>"date:D:S:d1"}
    @portlet.expects('params').returns(@params).at_least_once
  end

  test "Sort params" do
    SearchResult.expects(:find).with("X", {:start => 10, :portlet => @portlet, :site=>'default_collection', :sort=>"date:D:S:d1"})
    @portlet.render
  end

  test "Find narrow queries only if enabled" do
    @portlet.enable_narrow_your_search = "1"
    GSA::Appliance.any_instance.expects(:find_narrow_search_results).with("X")
    SearchResult.expects(:find).with("X", {:start => 10, :portlet => @portlet, :site=>'default_collection', :sort=>"date:D:S:d1"})
    @portlet.render
  end
end