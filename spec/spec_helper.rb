# encoding: utf-8

require 'support/detect_os'
require 'webmock/rspec'


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
  end
end

require 'tara'
