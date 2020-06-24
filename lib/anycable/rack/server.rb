# frozen_string_literal: true

require "anycable"

require "anycable/rack/hub"
require "anycable/rack/pinger"
require "anycable/rack/errors"
require "anycable/rack/middleware"
require "anycable/rack/logging"
require "anycable/rack/broadcast_subscribers/base_subscriber"
require "anycable/rack/coders/json"

module AnyCable # :nodoc: all
  module Rack
    class Server
      include Logging

      attr_reader :config,
        :broadcast,
        :coder,
        :hub,
        :middleware,
        :pinger,
        :rpc_host,
        :headers,
        :rpc_cli

      def initialize(config: AnyCable::Rack.config)
        @config = config
        @hub = Hub.new
        @pinger = Pinger.new
        # TODO: Support other coders
        @coder = Coders::JSON

        @broadcast = resolve_broadcast_adapter

        @middleware = Middleware.new(
          header_names: config.headers,
          pinger: pinger,
          hub: hub,
          rpc_host: config.rpc_host,
          coder: coder
        )

        log(:info) { "Using RPC server at #{config.rpc_host}" }
      end
      # rubocop:enable

      def start!
        log(:info) { "Starting..." }

        pinger.run

        broadcast.start

        if config.run_rpc
          require "anycable/cli"
          @rpc_cli = AnyCable::CLI.new(embedded: true)
          @rpc_cli.run
        end

        @_started = true
      end

      def shutdown
        log(:info) { "Shutting down..." }
        rpc_cli&.shutdown
        hub.broadcast_all(coder.encode(type: "disconnect", reason: "server_restart", reconnect: true))
      end

      def started?
        @_started == true
      end

      def stop
        return unless started?

        @_started = false
        broadcast_subscriber.stop
        pinger.stop
        hub.close_all
      end

      def call(env)
        middleware.call(env)
      end

      def inspect
        "#<AnyCable::Rack::Server(rpc_host: #{config.rpc_host}, headers: [#{config.headers.join(", ")}])>"
      end

      private

      def resolve_broadcast_adapter
        adapter = AnyCable.config.broadcast_adapter.to_s
        require "anycable/rack/broadcast_subscribers/#{adapter}_subscriber"

        if adapter.to_s == "redis"
          BroadcastSubscribers::RedisSubscriber.new(
            hub: hub,
            coder: coder,
            channel: AnyCable.config.redis_channel,
            **AnyCable.config.to_redis_params
          )
        elsif adapter.to_s == "http"
          BroadcastSubscribers::HTTPSubscriber.new(
            hub: hub,
            coder: coder,
            token: AnyCable.config.http_broadcast_secret,
            path: config.http_broadcast_path
          )
        else
          raise ArgumentError, "Unsupported broadcast adatper: #{adapter}. AnyCable Rack server only supports: redis, http"
        end
      end
    end
  end
end
