# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../../lib", __dir__)
require "anycable-rack-server"

ws_server = AnyCable::Rack::Server.new

app = Rack::Builder.new do
  map "/cable" do
    run ws_server
  end
end

ws_server.start!

run app
