# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'anycable/rack/version'

Gem::Specification.new do |s|
  s.name        = 'anycable-rack-server'
  s.version     = AnyCable::Rack::VERSION
  s.summary     = 'Anycable Rack Server'
  s.description = 'AnyCable-compatible Ruby Rack middleware'
  s.authors     = ['Yulia Oletskaya']
  s.email       = 'yulia.oletskaya@gmail.com'
  s.license     = 'MIT'

  s.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.require_paths = ['lib']

  s.add_dependency 'anycable', '~> 0.6'
  s.add_dependency 'websocket', '~> 1.2'
  s.add_dependency 'redis', '~> 4'

  s.add_development_dependency 'anyt', '~> 0.8.4'
  s.add_development_dependency 'minitest', '~> 5.10'
  s.add_development_dependency 'puma'
  s.add_development_dependency 'rake', '~> 12.3'
  s.add_development_dependency 'rubocop', "~> 0.60.0"
end
