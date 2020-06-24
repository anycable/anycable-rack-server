# frozen_string_literal: true

require "securerandom"
require "set"
require "json"

require "anycable/rack/rpc/client"
require "anycable/rack/logging"
require "anycable/rack/errors"

module AnyCable
  module Rack
    class Connection # :nodoc:
      include Logging

      attr_reader :coder,
        :headers,
        :hub,
        :socket,
        :rpc_client,
        :sid

      def initialize(socket, hub:, coder:, rpc_host:, headers:)
        @socket = socket
        @coder = coder
        @headers = headers
        @hub = hub
        @sid = SecureRandom.hex(6)

        @rpc_client = RPC::Client.new(rpc_host)

        @_identifiers = "{}"
        @_subscriptions = Set.new
        @_istate = {}
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
        command = decoded.delete("command")

        channel_identifier = decoded["identifier"]

        log(:debug) { "Command: #{decoded}" }

        case command
        when "subscribe" then subscribe(channel_identifier)
        when "unsubscribe" then unsubscribe(channel_identifier)
        when "message" then send_message(channel_identifier, decoded["data"])
        else
          log(:error, "Command not found #{command}")
        end
      rescue Exception => e # rubocop:disable Lint/RescueException
        log(:error, "Failed to execute command #{command}: #{e.message}")
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

      def rpc_connect
        rpc_client.connect(headers: headers, url: request.url)
      end

      def rpc_disconnect
        rpc_client.disconnect(
          identifiers: @_identifiers,
          subscriptions: @_subscriptions.to_a,
          headers: headers,
          url: request.url,
          state: @_cstate
        )
      end

      def rpc_command(command, identifier, data = "")
        rpc_client.command(
          command: command,
          identifier: identifier,
          connection_identifiers: @_identifiers,
          data: data,
          headers: headers,
          url: request.url,
          connection_state: @_cstate,
          state: @_istate[identifier]
        )
      end

      def subscribe(identifier)
        response = rpc_command("subscribe", identifier)
        if response.status == :SUCCESS
          @_subscriptions.add(identifier)
        elsif response.status == :ERROR
          log(:error, "RPC subscribe command failed: #{response.inspect}")
        end
        process_command(response, identifier)
      end

      def unsubscribe(identifier)
        response = rpc_command("unsubscribe", identifier)
        if response.status == :SUCCESS
          @_subscriptions.delete(identifier)
        elsif response.status == :ERROR
          log(:error, "RPC unsubscribe command failed: #{response.inspect}")
        end
        process_command(response, identifier)
      end

      def send_message(identifier, data)
        response = rpc_command("message", identifier, data)
        log(:error, "RPC message command failed: #{response.inspect}") if response.status == :ERROR
        process_command(response, identifier)
      end

      def process_command(response, identifier)
        response.transmissions.each { |transmission| transmit(decode(transmission)) }
        hub.remove_channel(socket, identifier) if response.stop_streams
        response.streams.each { |stream| hub.add_subscriber(stream, socket, identifier) }
        response.stopped_streams.each { |stream| hub.remove_subscriber(stream, socket, identifier) }

        @_istate[identifier] ||= {}
        @_istate[identifier].merge!(response.env.istate&.to_h || {})

        close_connection if response.disconnect
      end

      def process_open(response)
        response.transmissions&.each { |transmission| transmit(decode(transmission)) }
        if response.status == :SUCCESS
          @_identifiers = response.identifiers
          @_cstate = response.env.cstate&.to_h || {}
          hub.add_socket(socket, @_identifiers)
          log(:debug) { "Opened" }
        else
          log(:error, "RPC connection command failed: #{response.inspect}")
          close_connection
        end
      end

      def process_close(response)
        if response.status == :SUCCESS
          log(:debug) { "Closed" }
        else
          log(:error, "RPC disconnection command failed: #{response.inspect}")
        end
      end

      def reset_connection
        @_identifiers = "{}"
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

      def log(level, msg = nil)
        super(level, msg ? log_fmt(msg) : nil) { log_fmt(yield) }
      end

      def log_fmt(msg)
        "[sid=#{sid}] #{msg}"
      end
    end
  end
end
