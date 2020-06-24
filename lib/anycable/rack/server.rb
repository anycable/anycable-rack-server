# frozen_string_literal: true

require "anycable"

require "anycable/rack/hub"
require "anycable/rack/pinger"
require "anycable/rack/errors"
require "anycable/rack/middleware"
require "anycable/rack/logging"
require "anycable/rack/rpc_runner"
require "anycable/rack/broadcast_subscribers/base_subscriber"
require "anycable/rack/coders/json"

module AnyCable # :nodoc: all
  module Rack
    class Server
      include Logging

      DEFAULT_HEADERS = %w[cookie x-api-token].freeze

      attr_reader :broadcast,
        :coder,
        :hub,
        :middleware,
        :pinger,
        :rpc_host,
        :headers

      def initialize(*args)
        options = args.last.is_a?(Hash) ? args.last : {}

        @hub = Hub.new
        @pinger = Pinger.new
        @coder = options.fetch(:coder, Coders::JSON)

        @headers = options.fetch(:headers, DEFAULT_HEADERS)
        @rpc_host = options.fetch(:rpc_host)

        @broadcast = resolve_broadcast_adapter(options.fetch(:broadcast_adapter, :redis), **options)

        @middleware = Middleware.new(
          header_names: headers,
          pinger: pinger,
          hub: hub,
          rpc_host: rpc_host,
          coder: coder
        )

        log(:info) { "Using RPC server at #{rpc_host}" }
      end
      # rubocop:enable

      def start!
        log(:info) { "Starting..." }

        pinger.run

        broadcast.start

        @_started = true
      end

      def shutdown
        log(:info) { "Shutting down..." }
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
        "#<AnyCable::Rack::Server(rpc_host: #{rpc_host}, headers: [#{headers.join(", ")}])>"
      end

      private

      def resolve_broadcast_adapter(adapter, **options)
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
            token: options[:http_broadcast_secret],
            path: options[:http_broadcast_path]
          )
        else
          raise ArgumentError, "Unknown adatper: #{adatpter}"
        end
      end
    end
  end
end
