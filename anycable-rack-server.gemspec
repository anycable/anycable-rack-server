# frozen_string_literal: true
$LOAD_PATH.push File.expand_path('../lib', __FILE__)

require 'anycable/rack-server/version'

Gem::Specification.new do |s|
  s.name        = 'anycable-rack-server'
  s.version     = AnyCable::RackServer::VERSION
  s.summary     = 'Anycable Rack Server'
  s.description = 'AnyCable-compatible Ruby Rack middleware'
  s.authors     = ['Yulia Oletskaya']
  s.email       = 'yulia.oletskaya@gmail.com'
  s.license     = 'MIT'

  s.files         = Dir['lib/**/*', 'LICENSE', 'README.md']
  s.require_paths = ['lib']

  s.add_dependency 'anycable', '~> 0.6'
  s.add_dependency 'websocket', '~> 1.2'

  s.add_development_dependency 'anyt', '~> 0.8'
  s.add_development_dependency 'minitest', '~> 5.11'
  s.add_development_dependency 'rake', '~> 12.3'
end
