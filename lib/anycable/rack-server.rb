# frozen_string_literal: true

require 'anycable/rack-server/hub'
require 'anycable/rack-server/pinger'
require 'anycable/rack-server/middleware'
require 'anycable/rack-server/broadcast_adapters/hub_adapter'
require 'anycable/rack-server/coders/json'

module AnyCable
  module RackServer
    class << self
      attr_reader :hub, :pinger, :coder

      def setup!
        @hub     = Hub.new
        @pinger  = Pinger.new
        @coder   = Coders::JSON

        @_started = true
      end

      def started?
        @_started == true
      end

      def broadcast_adapter
        @broadcast_adapter ||= BroadcastAdapters::HubAdapter.new(hub, coder)
      end

      def middleware
        @middleware ||= Middleware.new(nil, pinger, hub, coder)
      end
    end
  end

  class << self
    def broadcast_adapter
      return super unless RackServer.started?

      RackServer.broadcast_adapter
    end

    def rack_middleware
      RackServer.started? ? RackServer.middleware : nil
    end
  end
end
