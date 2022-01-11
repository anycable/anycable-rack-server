# frozen_string_literal: true

require "websocket"

require "anycable/rack/connection"
require "anycable/rack/errors"
require "anycable/rack/socket"

module AnyCable
  module Rack
    class Middleware # :nodoc:
      PROTOCOLS = %w[actioncable-v1-json actioncable-v1-msgpack actioncable-unsupported actioncable-v1-protobuf].freeze

      attr_reader :pinger,
        :hub,
        :coder,
        :rpc_client,
        :header_names

      def initialize(pinger:, hub:, coder:, rpc_client:, header_names:)
        @pinger = pinger
        @hub = hub
        @coder = coder
        @rpc_client = rpc_client
        @header_names = header_names
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
        raise Errors::HijackNotAvailable unless env["rack.hijack"]

        env["rack.hijack"].call
        send_handshake(env)
      end

      def send_handshake(env)
        handshake.from_rack(env)
        env["rack.hijack_io"].write(handshake.to_s)
      end

      def listen_socket(env)
        socket = Socket.new(env, env["rack.hijack_io"], handshake.version)
        init_connection(socket)
        init_pinger(socket)
        socket.listen
      end

      def not_found
        [404, {"Content-Type" => "text/plain"}, ["Not Found"]]
      end

      def websocket?(env)
        env["HTTP_UPGRADE"] == "websocket"
      end

      def init_connection(socket)
        connection = Connection.new(
          socket,
          hub: hub,
          coder: coder,
          rpc_client: rpc_client,
          headers: fetch_headers(socket.request)
        )
        socket.onopen { connection.handle_open }
        socket.onclose { connection.handle_close }
        socket.onmessage { |data| connection.handle_command(data) }
      end

      def init_pinger(socket)
        pinger.add(socket)
        socket.onclose { pinger.remove(socket) }
      end

      def fetch_headers(request)
        header_names.each_with_object({}) do |name, acc|
          header_val = request.env["HTTP_#{name.tr("-", "_").upcase}"]
          acc[name] = header_val unless header_val.nil? || header_val.empty?
        end
      end
    end
  end
end
