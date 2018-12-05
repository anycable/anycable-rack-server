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

      def handle_open
        response = rpc_connect
        process_open(response)
      end

      def handle_close
        response = rpc_disconnect
        process_close(response)
        reset_connection
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

      private

      def transmit(cable_message)
        socket.transmit(encode(cable_message))
      end

      def close
        socket.close
      end

      def request
        socket.request
      end

      def request_path
        request.fullpath
      end

      def rpc_connect
        rpc_client.connect(headers: headers, path: request_path)
      end

      def rpc_disconnect
        rpc_client.disconnect(
          identifiers: @_identifiers,
          subscriptions: @_subscriptions.to_a,
          headers: headers,
          path: request_path
        )
      end

      def rpc_command(command, identifier, data = '')
        rpc_client.command(
          command: command,
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: data
        )
      end

      def subscribe(identifier)
        response = rpc_command('subscribe', identifier)
        if response.status == :SUCCESS
          @_subscriptions.add(identifier)
        else
          log(:debug, log_fmt("RPC subscribe command failed: #{response.inspect}"))
        end
        process_command(response, identifier)
      end

      def unsubscribe(identifier)
        response = rpc_command('unsubscribe', identifier)
        if response.status == :SUCCESS
          @_subscriptions.delete(identifier)
        else
          log(:debug, log_fmt("RPC unsubscribe command failed: #{response.inspect}"))
        end
        process_command(response, identifier)
      end

      def send_message(identifier, data)
        response = rpc_command('message', identifier, data)
        unless response.status == :SUCCESS
          log(:debug, log_fmt("RPC message command failed: #{response.inspect}"))
        end
        process_command(response, identifier)
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

      def process_command(response, identifier)
        response.transmissions.each { |transmission| transmit(decode(transmission)) }
        hub.remove_channel(socket, identifier) if response.stop_streams
        response.streams.each { |stream| hub.add_subscriber(stream, socket, identifier) }
        close_connection if response.disconnect
      end

      def process_open(response)
        if response.status == :SUCCESS
          send_welcome_message
          @_identifiers = response.identifiers
          response.transmissions.each { |transmission| transmit(decode(transmission)) }
          log(:debug) { log_fmt('Opened') }
        else
          log(:error, log_fmt("RPC connection command failed: #{response.inspect}"))
          close_connection
        end
      end

      def process_close(response)
        if response.status == :SUCCESS
          log(:debug) { log_fmt('Closed') }
        else
          log(:error, log_fmt("RPC disconnection command failed: #{response.inspect}"))
        end
      end

      def reset_connection
        @_identifiers = '{}'
        @_subscriptions = []

        hub.remove_socket(socket)
      end

      def close_connection
        reset_connection
        close
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
