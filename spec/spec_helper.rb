# encoding: utf-8

require 'support/detect_os'
require 'support/acceptance_helpers'
require 'webmock/rspec'
require 'rubygems/package'
require 'zlib'

RSpec.configure do |config|
  config.before :all do
    WebMock.disable!
  end
end


unless ENV['COVERAGE'] == 'no'
  require 'coveralls'
  require 'simplecov'

  if ENV.include?('TRAVIS')
    Coveralls.wear!
    SimpleCov.formatter = Coveralls::SimpleCov::Formatter
  end

  SimpleCov.start do
    add_group 'Source', 'lib'
    add_group 'Unit tests', 'spec/tara'
    add_group 'Acceptance tests', 'spec/acceptance'
    add_group 'Integration tests', 'spec/integration'
  end
end

require 'tara'
