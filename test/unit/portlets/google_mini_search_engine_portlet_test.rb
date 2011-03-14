require 'test_helper'

class GoogleMiniSearchEngineTest < ActiveSupport::TestCase

  test "Should be able to create new instance of a portlet" do
    assert GoogleMiniSearchEnginePortlet.create!(:name => "New Portlet")
  end



  test "Path attribute can be set in constructor" do
    portlet = GoogleMiniSearchEnginePortlet.create!(:name=>"Engine", :path => "/engine")
    assert_equal "/engine", portlet.path
  end
end