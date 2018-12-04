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

      attr_reader :coder,
                  :header_names,
                  :hub,
                  :socket,
                  :rpc_client,
                  :server_id

      def initialize(socket, hub, coder, host, header_names, server_id)
        @socket       = socket
        @coder        = coder
        @hub          = hub
        @header_names = header_names
        @server_id    = server_id

        @rpc_client = RPC::Client.new(host)

        @_identifiers   = '{}'
        @_subscriptions = Set.new
      end

      # TODO: refactor, add separate response handlers for major message types
      def handle_open
        response = connect_rpc
        if response.status == :SUCCESS
          send_welcome_message
          @_identifiers = response.identifiers
          log(:debug) { log_fmt('Opened') }
        else
          @_identifiers = '{}'
          log(:error, log_fmt("RPC connection command failed: #{response.inspect}"))
          close
        end
        response.transmissions.each { |transmission| transmit(decode(transmission)) }
      end

      def handle_close
        disconnect!
        log(:debug) { log_fmt('Closed') }
        response = disconnect_rpc
        if response.status == :SUCCESS
          @_identifiers = '{}'
          @_subscriptions = []
        else
          log(:error, log_fmt("RPC disconnection command failed: #{response.inspect}"))
        end
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
        socket.transmit(encode(cable_message))
      end

      def close
        socket.close
      end

      # Rack::Request instance of underlying socket
      def request
        socket.request
      end

      def request_path
        request.fullpath
      end

      def disconnected?
        @_disconnected == true
      end

      private

      def disconnect!
        @_disconnected = true
      end

      def connect_rpc
        rpc_client.connect(headers: headers, path: request_path)
      end

      def disconnect_rpc
        rpc_client.disconnect(
          identifiers: @_identifiers,
          subscriptions: @_subscriptions.to_a,
          headers: headers,
          path: request_path
        )
      end

      def subscribe(identifier)
        response = execute_command('subscribe', identifier)
        if response.status == :SUCCESS
          @_subscriptions.add(identifier)
        else
          log(:error, log_fmt("RPC subscribe command failed: #{response.inspect}"))
        end
        process_result(response, identifier)
      end

      def send_message(identifier, data)
        response = execute_command('message', identifier, data)
        unless response.status == :SUCCESS
          log(:error, log_fmt("RPC message command failed: #{response.inspect}"))
        end
        process_result(response, identifier)
      end

      def unsubscribe(identifier)
        response = execute_command('unsubscribe', identifier)
        if response.status == :SUCCESS
          @_subscriptions.delete(identifier)
        else
          log(:error, log_fmt("RPC unsubscribe command failed: #{response.inspect}"))
        end
        process_result(response, identifier)
      end

      def headers
        @headers ||= begin
          header_names.inject({}) do |acc, name|
            header_val = request.env["HTTP_#{name.gsub(/-/,'_').upcase}"]
            acc[name]  = header_val unless header_val.nil? || header_val.empty?
            acc
          end
        end
      end

      def execute_command(command, identifier, data = '')
        rpc_client.command(
          command: command,
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: data
        )
      end

      def process_result(response, identifier)
        response.transmissions.each { |transmission| transmit(decode(transmission)) }
        hub.remove_channel(socket, identifier) if response.stop_streams
        response.streams.each { |stream| hub.add_subscriber(stream, socket, identifier) }
      end

      def encode(cable_message)
        coder.encode(cable_message)
      end

      def decode(websocket_message)
        coder.decode(websocket_message)
      end

      def send_welcome_message
        transmit(type: :welcome)
      end

      def log_fmt(msg)
        "[connection:#{server_id}] #{msg}"
      end
    end
  end
end
