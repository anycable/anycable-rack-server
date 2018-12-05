# frozen_string_literal: true

require 'minitest/autorun'
require 'anycable-rack-server'
require 'anycable/broadcast_adapters/redis'

class TestRackServer < Minitest::Test
  def teardown
    AnyCable::RackServer.stop
  end

  def test_start
    assert_equal false, AnyCable::RackServer.started?
    AnyCable::RackServer.start
    assert_equal true, AnyCable::RackServer.started?
    assert_equal AnyCable::RackServer::DEFAULT_OPTIONS[:rpc_host], AnyCable::RackServer.middleware.rpc_host
    assert_equal AnyCable::RackServer::DEFAULT_OPTIONS[:headers], AnyCable::RackServer.middleware.headers
  end

  def test_rack_new
    assert_equal false, AnyCable::RackServer.started?
    AnyCable::Rack.new(nil, { rpc_host: 'rpc:25025', headers: 'origin' })
    assert_equal true, AnyCable::RackServer.started?
    assert_equal 'rpc:25025', AnyCable::RackServer.middleware.rpc_host
    assert_equal 'origin', AnyCable::RackServer.middleware.headers
  end
end
