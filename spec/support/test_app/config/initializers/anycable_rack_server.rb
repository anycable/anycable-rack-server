$LOAD_PATH.push File.expand_path('../../../../../../lib', __FILE__)
require 'anycable'
require 'anycable-rack-server'

AnyCable::RackServer.setup!
