# frozen_string_literal: true

require_relative "lib/anycable/rack/version"

Gem::Specification.new do |s|
  s.name = "anycable-rack-server"
  s.version = AnyCable::Rack::VERSION
  s.summary = "AnyCable Rack Server"
  s.description = "AnyCable-compatible Ruby Rack middleware"
  s.authors = ["Yulia Oletskaya", "Vladimir Dementyev"]
  s.email = "yulia.oletskaya@gmail.com"
  s.license = "MIT"

  s.files = Dir["lib/**/*", "LICENSE", "README.md"]
  s.require_paths = ["lib"]

  s.add_dependency "anyway_config", ">= 2.1.0"
  s.add_dependency "anycable", "~> 1.1.0"
  s.add_dependency "connection_pool", "~> 2.2"
  s.add_dependency "websocket", "~> 1.2"

  s.add_development_dependency "anyt"
  s.add_development_dependency "minitest", "~> 5.10"
  s.add_development_dependency "puma"
  s.add_development_dependency "rake", ">= 13.0"
  s.add_development_dependency "redis", "~> 4"
  s.add_development_dependency "rubocop", ">= 0.80"
end
