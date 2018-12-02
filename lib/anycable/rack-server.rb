# frozen_string_literal: true

require 'json'
require 'set'
require 'anycable/rack-server/hub'
require 'anycable/rack-server/pinger'
require 'anycable/rack-server/middleware'
require 'anycable/rack-server/broadcast_adapters/hub_adapter'
require 'anycable/rack-server/coders/json'

module AnyCable
  module RackServer
    class << self
      attr_reader :hub, :pinger, :coder, :broadcast_adapter, :middleware

      def setup!
        @hub     = Hub.new
        @pinger  = Pinger.new
        @coder   = Coders::JSON

        @broadcast_adapter = BroadcastAdapters::HubAdapter.new(hub, coder)
        @middleware = Middleware.new(nil, pinger, hub, coder)

        @_started = true
      end

      def started?
        @_started == true
      end
    end
  end

  class << self
    def broadcast_adapter
      return super unless RackServer.started?

      RackServer.broadcast_adapter
    end

    def rack_middleware
      RackServer.middleware
    end
  end
end
