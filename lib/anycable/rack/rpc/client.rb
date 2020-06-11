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

        def connect(headers:, url:)
          request = ConnectionRequest.new(env: Env.new(headers: headers, url: url))
          stub.connect(request)
        end

        def command(command:, identifier:, connection_identifiers:, data:, headers:, url:, connection_state: nil, state: nil)
          message = CommandMessage.new(
            command: command,
            identifier: identifier,
            connection_identifiers: connection_identifiers,
            data: data,
            env: Env.new(
              headers: headers,
              url: url,
              cstate: connection_state,
              istate: state
            )
          )
          stub.command(message)
        end

        def disconnect(identifiers:, subscriptions:, headers:, url:, state: nil)
          request = DisconnectRequest.new(
            identifiers: identifiers,
            subscriptions: subscriptions,
            env: Env.new(
              headers: headers,
              url: url,
              cstate: state
            )
          )
          stub.disconnect(request)
        end
      end
    end
  end
end
