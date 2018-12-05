# frozen_string_literal: true

require 'redis'

module AnyCable
  module RackServer
    module BroadcastSubscribers
      class RedisSubscriber
        attr_reader :hub, :coder, :redis_conn

        def initialize(hub:, coder:, options:)
          @hub        = hub
          @coder      = coder
          @redis_conn = ::Redis.new(options)
          @_threads   = []
        end

        def subscribe(channel)
          Thread.new do
            redis_conn.subscribe(channel) do |on|
              on.message { |_channel, msg|  handle_message(msg) }
            end
          end
        end

        def unsubscribe(channel)
          redis_conn.unsubscribe(channel) if redis_conn.subscribed?
        end

        private

        def handle_message(msg)
          data = JSON.parse(msg)
          hub.broadcast(data['stream'], data['data'], coder)
        end
      end
    end
  end
end
