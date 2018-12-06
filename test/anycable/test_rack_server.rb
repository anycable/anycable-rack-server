# frozen_string_literal: true

require 'minitest/autorun'
require 'anycable-rack-server'

class TestRackServer < Minitest::Test
  def teardown
    AnyCable::RackServer.stop
  end

  def test_start
    AnyCable::RackServer.start
    assert_equal true, AnyCable::RackServer.started?
    assert_equal AnyCable::RackServer::DEFAULT_OPTIONS[:rpc_host], AnyCable::RackServer.middleware.rpc_host
    assert_equal AnyCable::RackServer::DEFAULT_OPTIONS[:headers], AnyCable::RackServer.middleware.headers
    assert_equal [AnyCable.config.redis_channel], AnyCable::RackServer.broadcast_subscriber.threads.keys
  end

  def test_rack_new
    AnyCable::Rack.new(nil, { rpc_host: 'rpc:25025', headers: 'origin' })
    assert_equal true, AnyCable::RackServer.started?
    assert_equal 'rpc:25025', AnyCable::RackServer.middleware.rpc_host
    assert_equal 'origin', AnyCable::RackServer.middleware.headers
    assert_equal [AnyCable.config.redis_channel], AnyCable::RackServer.broadcast_subscriber.threads.keys
  end

  def test_stop
    AnyCable::RackServer.start
    AnyCable::RackServer.stop
    assert_equal false, AnyCable::RackServer.started?
    assert_equal [], AnyCable::RackServer.broadcast_subscriber.threads.keys
  end
end
