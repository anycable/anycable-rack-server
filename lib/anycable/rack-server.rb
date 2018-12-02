# frozen_string_literal: true

require 'json'
require 'set'
require 'anycable/rack-server/hub'
require 'anycable/rack-server/pinger'
require 'anycable/rack-server/errors'
require 'anycable/rack-server/middleware'
require 'anycable/rack-server/broadcast_adapters/hub_adapter'
require 'anycable/rack-server/coders/json'

module AnyCable
  module RackServer
    class << self
      attr_reader :hub, :pinger, :coder, :broadcast_adapter

      def setup!
        @hub     = Hub.new
        @pinger  = Pinger.new
        @coder   = Coders::JSON

        @broadcast_adapter = BroadcastAdapters::HubAdapter.new(hub, coder)
        @_middleware = Middleware.new(nil, pinger, hub, coder)

        @_started = true
      end

      def started?
        @_started == true
      end

      def middleware
        @middleware ||= begin
          unless started?
            msg = "Please, run `AnyCable::RackServer.setup!` before using the middleware"
            raise Errors::MiddlewareSetup, msg
          end
          @_middleware
        end
      end
    end
  end

  class << self
    def broadcast_adapter
      return super unless RackServer.started?

      RackServer.broadcast_adapter
    end
  end

  module Rack
    class << self
      def call(env)
        AnyCable::RackServer.middleware.call(env)
      end
    end
  end
end
