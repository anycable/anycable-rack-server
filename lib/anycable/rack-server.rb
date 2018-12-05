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
require 'anycable/rack-server/broadcast_adapters/hub_adapter'
require 'anycable/rack-server/coders/json'

module AnyCable
  module RackServer
    DEFAULT_OPTIONS = {
      rpc_host: 'rpc:50051',
      headers:  ['cookie', 'x-api-token']
    }.freeze

    class << self
      attr_reader :broadcast_adapter,
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
        @broadcast_adapter = BroadcastAdapters::HubAdapter.new(hub, coder)
        @middleware = Middleware.new(
          nil,
          pinger:    pinger,
          hub:       hub,
          coder:     coder,
          rpc_host:  rpc_host,
          headers:   headers,
          server_id: server_id
        )

        @_started = true
      end

      def started?
        @_started == true
      end

      def stop
        @_started = false
      end

      private

      def parse_env_headers
        headers = ENV['ANYCABLE_HEADERS'].to_s.split(',')
        return nil if headers.empty?
        headers
      end
    end
  end

  class << self
    alias_method :original_adapter, :broadcast_adapter

    def broadcast_adapter
      return original_adapter unless AnyCable::RackServer.started?

      AnyCable::RackServer.broadcast_adapter
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
