# frozen_string_literal: true

require 'set'
require 'json'
require 'anycable'
require 'websocket'
require 'securerandom'
require 'anycable/rack-server/hub'
require 'anycable/rack-server/pinger'
require 'anycable/rack-server/errors'
require 'anycable/rack-server/middleware'
require 'anycable/rack-server/broadcast_subscribers/redis_subscriber'
require 'anycable/rack-server/coders/json'

module AnyCable
  module RackServer
    DEFAULT_OPTIONS = {
      rpc_host: 'rpc:50051',
      headers:  ['cookie', 'x-api-token']
    }.freeze

    class << self
      attr_reader :broadcast_subscriber,
                  :coder,
                  :hub,
                  :middleware,
                  :pinger,
                  :server_id

      def start(options = {})
        options  = DEFAULT_OPTIONS.merge(options)
        @hub     = Hub.new
        @pinger  = Pinger.new
        @coder   = Coders::JSON

        rpc_host = ENV['ANYCABLE_RPC_HOST'] || options[:rpc_host]
        headers  = parse_env_headers || options[:headers]

        @server_id = "anycable-rack-server-#{SecureRandom.hex}"
        @middleware = Middleware.new(
          nil,
          pinger:    pinger,
          hub:       hub,
          coder:     coder,
          rpc_host:  rpc_host,
          headers:   headers,
          server_id: server_id
        )

        broadcast_subscribe

        @_started = true
      end

      def started?
        @_started == true
      end

      def stop
        return unless started?

        @_started = false
        broadcast_subscriber.unsubscribe(@_redis_channel)
        pinger.stop

        hub.sockets.each do |socket|
          hub.remove_socket(socket)
          socket.close
        end
      end

      private

      def broadcast_subscribe
        @_redis_params  = AnyCable.config.to_redis_params
        @_redis_channel = AnyCable.config.redis_channel

        @broadcast_subscriber = BroadcastSubscribers::RedisSubscriber.new(
          hub:     @hub,
          coder:   @coder,
          options: @_redis_params
        )

        @broadcast_subscriber.subscribe(@_redis_channel)
      end

      def parse_env_headers
        headers = ENV['ANYCABLE_HEADERS'].to_s.split(',')
        return nil if headers.empty?
        headers
      end
    end
  end

  class Rack
    def initialize(_app = nil, options = {})
      AnyCable::RackServer.start(options)
    end

    def call(env)
      AnyCable::RackServer.middleware.call(env)
    end
  end
end
