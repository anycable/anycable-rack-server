# frozen_string_literal: true

require "redis"
require "json"

module AnyCable
  module Rack
    module BroadcastSubscribers
      # Redis Pub/Sub subscriber
      class RedisSubscriber
        attr_reader :hub, :coder, :redis_conn, :threads

        def initialize(hub:, coder:, **options)
          @hub        = hub
          @coder      = coder
          @redis_conn = ::Redis.new(options)
          @threads    = {}
        end

        def subscribe(channel)
          @threads[channel] = Thread.new do
            redis_conn.subscribe(channel) do |on|
              on.message { |_channel, msg| handle_message(msg) }
            end
          end
        end

        def unsubscribe(channel)
          @threads[channel]&.terminate
          @threads.delete(channel)
        end

        private

        def handle_message(msg)
          data = JSON.parse(msg)
          hub.broadcast(data["stream"], data["data"], coder)
        end
      end
    end
  end
end
