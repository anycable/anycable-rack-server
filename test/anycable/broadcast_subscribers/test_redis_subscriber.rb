# frozen_string_literal: true

require 'minitest/autorun'
require 'anycable-rack-server'

class TestRedisSubscriber < Minitest::Test
  attr_reader :channel, :redis_mock

  def setup
    @channel = 'test_channel'
    @redis_mock = Minitest::Mock.new

    def redis_mock.subscribe(channel, &block)
      true
    end
    def redis_mock.unsubscribe(channel)
      true
    end
  end

  def test_subscribe
    ::Redis.stub(:new, redis_mock) do
      broadcast_subscriber = AnyCable::RackServer::BroadcastSubscribers::RedisSubscriber.new(
        hub:     {},
        coder:   {},
        options: {}
      )

      broadcast_subscriber.subscribe(channel)
      assert_equal [channel], broadcast_subscriber.threads.keys
    end
  end

  def test_unsubscribe
    ::Redis.stub(:new, redis_mock) do
      broadcast_subscriber = AnyCable::RackServer::BroadcastSubscribers::RedisSubscriber.new(
        hub:     {},
        coder:   {},
        options: {}
      )

      broadcast_subscriber.subscribe(channel)
      broadcast_subscriber.unsubscribe(channel)
      assert_equal [], broadcast_subscriber.threads.keys
    end
  end
end
