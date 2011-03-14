ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
# require 'test/unit'
require 'rails/test_help'

require "rexml/document"

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
end
require 'mocha'

