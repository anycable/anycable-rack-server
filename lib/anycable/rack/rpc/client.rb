# frozen_string_literal: true

require "grpc"

module AnyCable
  module Rack
    module RPC
      # AnyCable RPC client
      class Client
        attr_reader :stub

        def initialize(host)
          @stub = AnyCable::RPC::Service.rpc_stub_class.new(host, :this_channel_is_insecure)
        end

        def connect(headers:, path:)
          request = ConnectionRequest.new(headers: headers, path: path)
          stub.connect(request)
        end

        def command(command:, identifier:, connection_identifiers:, data:)
          message = CommandMessage.new(
            command: command,
            identifier: identifier,
            connection_identifiers: connection_identifiers,
            data: data
          )
          stub.command(message)
        end

        def disconnect(identifiers:, subscriptions:, headers:, path:)
          request = DisconnectRequest.new(
            identifiers: identifiers,
            subscriptions: subscriptions,
            headers: headers,
            path: path
          )
          stub.disconnect(request)
        end
      end
    end
  end
end
