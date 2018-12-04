$LOAD_PATH.push File.expand_path('../../../lib', __FILE__)
require 'anycable-rack-server'

AnyCable::RackServer.setup!

class AnytApp
  def call(env)
    request = Rack::Request.new(env)

    return AnyCable::Rack.call(env) if request.path_info =~ /cable/

    [200, {'Content-Type' => 'text/html'}, ['Welcome to Anyt::App']]
  end
end

run AnytApp.new
