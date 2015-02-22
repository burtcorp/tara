# encoding: utf-8

$: << File.expand_path('../lib', __FILE__)

require 'tara/version'


Gem::Specification.new do |s|
  s.name        = 'tara'
  s.version     = Tara::VERSION.dup
  s.platform    = 'ruby'
  s.authors     = ['Mathias Söderberg']
  s.email       = ['mths@sdrbrg.se']
  s.homepage    = 'http://github.com/mthssdrbrg/tara'
  s.summary     = %q{Packs your Ruby app as a standalone archive}
  s.description = %q{Tara packs your Ruby app into a standalone archive with gems and a Ruby runtime}
  s.license     = 'BSD-3-Clause'
  s.files       = Dir['lib/**/*.rb']
  s.require_paths = %w[lib]
end
