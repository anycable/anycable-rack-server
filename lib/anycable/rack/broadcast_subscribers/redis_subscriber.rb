# frozen_string_literal: true

gem "redis", "~> 4"

require "redis"
require "json"

module AnyCable
  module Rack
    module BroadcastSubscribers
      # Redis Pub/Sub subscriber
      class RedisSubscriber < BaseSubscriber
        attr_reader :redis_conn, :thread, :channel

        def initialize(hub:, coder:, channel:, **options)
          super
          @redis_conn = ::Redis.new(options)
          @channel = channel
        end

        def start
          subscribe(channel)

          log(:info) { "Subscribed to #{channel}" }
        end

        def stop
          thread&.terminate
        end

        def subscribe(channel)
          @thread ||= Thread.new do
            Thread.current.abort_on_exception = true

            redis_conn.without_reconnect do
              redis_conn.subscribe(channel) do |on|
                on.subscribe do |chan, count|
                  log(:debug) { "Redis subscriber connected to #{chan} (#{count})" }
                end

                on.unsubscribe do |chan, count|
                  log(:debug) { "Redis subscribed disconnected from #{chan} (#{count})" }
                end

                on.message do |_channel, msg|
                  handle_message(msg)
                end
              end
            end
          end
        end
      end
    end
  end
end
