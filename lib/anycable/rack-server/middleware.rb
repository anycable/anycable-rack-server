# frozen_string_literal: true

require 'anycable/rack-server/connection'
require 'anycable/rack-server/errors'
require 'anycable/rack-server/socket'

module AnyCable
  module RackServer
    class Middleware
      PROTOCOLS = ['actioncable-v1-json', 'actioncable-unsupported'].freeze
      attr_reader :pinger,
                  :hub,
                  :coder,
                  :rpc_host,
                  :headers,
                  :server_id

      def initialize(_app, pinger:, hub:, coder:, rpc_host:, headers:, server_id:)
        @pinger    = pinger
        @hub       = hub
        @coder     = coder
        @rpc_host  = rpc_host
        @headers   = headers
        @server_id = server_id
      end

      def call(env)
        return not_found unless websocket?(env)

        rack_hijack(env)
        listen_socket(env)

        [-1, {}, []]
      end

      private

      def handshake
        @handshake ||= WebSocket::Handshake::Server.new(protocols: PROTOCOLS)
      end

      def rack_hijack(env)
        raise Errors::HijackNotAvailable unless env['rack.hijack']

        env['rack.hijack'].call
        send_handshake(env)
      end

      def send_handshake(env)
        handshake.from_rack(env)
        env['rack.hijack_io'].write(handshake.to_s)
      end

      def listen_socket(env)
        socket = Socket.new(env, env['rack.hijack_io'], handshake.version)
        init_connection(socket)
        init_pinger(socket)
        socket.listen
      end

      def not_found
        [404, { 'Content-Type' => 'text/plain' }, ['Not Found']]
      end

      def websocket?(env)
        env['HTTP_UPGRADE'] == 'websocket'
      end

      def init_connection(socket)
        connection = Connection.new(socket, hub, coder, rpc_host, headers, server_id)
        socket.onopen { connection.handle_open }
        socket.onclose { connection.handle_close }
        socket.onmessage { |data| connection.handle_command(data) }
      end

      def init_pinger(socket)
        pinger.add(socket)
        socket.onclose { pinger.remove(socket) }
      end
    end
  end
end
