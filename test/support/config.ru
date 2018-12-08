$LOAD_PATH.push File.expand_path('../../../lib', __FILE__)
require 'anycable-rack-server'

class AnytApp
  def initialize(app)
    @app = app
  end

  def call(env)
    request = Rack::Request.new(env)

    return @app.call(env) if request.path_info =~ /cable/

    [200, {'Content-Type' => 'text/html'}, ['Welcome to Anyt::App']]
  end
end

ws_server = AnyCable::Rack.new
run AnytApp.new(ws_server)
