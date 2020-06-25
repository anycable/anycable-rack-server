# frozen_string_literal: true

require "connection_pool"
require "grpc"

module AnyCable
  module Rack
    module RPC
      # AnyCable RPC client
      class Client
        attr_reader :pool, :metadata

        def initialize(host:, size:, timeout:)
          @pool = ConnectionPool.new(size: size, timeout: timeout) do
            AnyCable::RPC::Service.rpc_stub_class.new(host, :this_channel_is_insecure)
          end
          @metadata = {metadata: {"protov" => "v1"}}.freeze
        end

        def connect(headers:, url:)
          request = ConnectionRequest.new(env: Env.new(headers: headers, url: url))
          pool.with do |stub|
            stub.connect(request, metadata)
          end
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
          pool.with do |stub|
            stub.command(message, metadata)
          end
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
          pool.with do |stub|
            stub.disconnect(request, metadata)
          end
        end
      end
    end
  end
end
