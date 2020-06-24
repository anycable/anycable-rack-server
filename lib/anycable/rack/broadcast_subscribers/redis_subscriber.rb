# frozen_string_literal: true

gem "redis", "~> 4"

require "redis"
require "json"

module AnyCable
  module Rack
    module BroadcastSubscribers
      # Redis Pub/Sub subscriber
      class RedisSubscriber < BaseSubscriber
        attr_reader :redis_conn, :threads, :channel

        def initialize(hub:, coder:, channel:, **options)
          super
          @redis_conn = ::Redis.new(options)
          @channel = channel
          @threads = {}
        end

        def start
          subscribe(channel)

          log(:info) { "Subscribed to #{channel}" }
        end

        def stop
          unsubscribe(channel)
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
      end
    end
  end
end
