# frozen_string_literal: true

require 'anycable'

# anycable 0.5 compatibility
AnyCable = Anycable

$LOAD_PATH.push File.expand_path('../../../../../../lib', __FILE__)
require 'anycable-rack-server'

AnyCable::RackServer.setup!

Thread.new { AnyCable::Server.start }

