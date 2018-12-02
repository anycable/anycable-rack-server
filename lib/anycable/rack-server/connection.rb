# frozen_string_literal: true

require 'anycable/rack-server/rpc/client'
require 'anycable/rack-server/logging'
require 'anycable/rack-server/errors'

module AnyCable
  # rubocop:disable Metrics/LineLength
  module RackServer
    class Connection
      # rubocop:enable Metrics/LineLength
      include Logging

      attr_reader :coder, :rpc_client, :socket, :hub

      def initialize(socket, hub, coder)
        @socket = socket
        @coder = coder
        @hub = hub

        host = ENV['ANYCABLE_RPC_HOST']
        @rpc_client = RPC::Client.new(host)

        @_identifiers = ''
        @_subscriptions = Set.new
      end

      def handle_open
        connect_rpc
        connect if respond_to?(:connect)
        log(:debug) { log_fmt('Opened') }

      rescue Errors::Unauthorized
        log(:debug) { log_fmt('Authorization failed') }
        close
      end

      def handle_close
        disconnected!
        disconnect if respond_to?(:disconnect)
        log(:debug) { log_fmt('Closed') }
        disconnect_rpc
        hub.remove_socket(socket)
      end

      def handle_command(websocket_message)
        decoded = decode(websocket_message)
        command = decoded.delete('command')

        channel_identifier = decoded['identifier']

        case command
        when 'subscribe'   then subscribe(channel_identifier)
        when 'unsubscribe' then unsubscribe(channel_identifier)
        when 'message'     then send_message(channel_identifier, decoded['data'])
        else
          raise Errors::UnknownCommand, "Command not found #{command}"
        end
      end

      def transmit(cable_message)
        return if disconnected?
        socket.transmit encode(cable_message)
      end

      def close
        socket.close
      end

      # Rack::Request instance of underlying socket
      def request
        socket.request
      end

      # Request cookies
      def cookies
        request.cookies
      end

      def disconnected?
        @_disconnected == true
      end

      private

      def disconnected!
        @_disconnected = true
      end

      # TODO: handle gRPC exceptions
      def connect_rpc
        response = rpc_client.connect(headers: headers, path: request.url)
        if response.status == :SUCCESS
          @_identifiers = response['identifiers']
          # response['transmissions'].each { |transmission| transmit(decode(transmission)) }
        else
          @_identifiers = ''
          log(:error, log_fmt("RPC connection command failed: #{response.inspect}"))
          close
        end
      end

      def disconnect_rpc
        response = rpc_client.disconnect(
          identifiers: @_identifiers,
          subscriptions: @_subscriptions.to_a,
          headers: headers,
          path: request.url
        )
        if response.status == :SUCCESS
          @_identifiers = ''
          @_subscriptions = []
        else
          log(:error, log_fmt("RPC disconnection command failed: #{response.inspect}"))
        end
      end

      def subscribe(identifier)
        response = rpc_client.command(
          command: 'subscribe',
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: ''
        )
        if response.status == :SUCCESS
          @_subscriptions.add(identifier)
          process_command_result(response, identifier)
        else
          log(:error, log_fmt("RPC subscribe command failed: #{response.inspect}"))
        end
      end

      def send_message(identifier, data)
        response = rpc_client.command(
          command: 'message',
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: data
        )
        if response.status == :SUCCESS
          process_command_result(response, identifier)
        else
          log(:error, log_fmt("RPC message command failed: #{response.inspect}"))
        end
      end

      def unsubscribe(identifier)
        response = rpc_client.command(
          command: 'unsubscribe',
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: ''
        )
        if response.status == :SUCCESS
          @_subscriptions.delete(identifier)
          process_command_result(response, identifier)
        else
          log(:error, log_fmt("RPC unsubscribe command failed: #{response.inspect}"))
        end
      end

      def headers
        @headers ||= { "Cookie" => request.cookies.map {  |k,v| "#{k}=#{v};"}.join }
      end

      def process_command_result(response, identifier)
        response['transmissions'].each { |transmission| transmit(decode(transmission)) }
        hub.remove_channel(socket, identifier) if response['stop_streams']
        response['streams'].each { |stream| hub.add_subscriber(stream, socket, identifier) }
      end

      def encode(cable_message)
        coder.encode(cable_message)
      end

      def decode(websocket_message)
        coder.decode(websocket_message)
      end

      def log_fmt(msg)
        "[connection:#{@_identifiers}] #{msg}"
      end
    end
  end
end
