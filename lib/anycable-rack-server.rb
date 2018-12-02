# frozen_string_literal: true

require 'anycable'
require 'anycable/rack-server'

hub    = AnyCable::RackServer::Hub.new
pinger = AnyCable::RackServer::Pinger.new
coder  = AnyCable::RackServer::Coders::JSON

Anycable # init
AnyCable::Rack = AnyCable::RackServer::Middleware.new(nil, pinger, hub, coder)
AnyCable.broadcast_adapter = AnyCable::RackServer::BroadcastAdapters::HubAdapter.new(hub, coder)
