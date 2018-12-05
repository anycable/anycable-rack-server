# frozen_string_literal: true

require 'minitest/autorun'
require 'anycable-rack-server'

class TestHubAdapter < Minitest::Test
  def setup
    @coder = AnyCable::RackServer::Coders::JSON
    @hub = MiniTest::Mock.new
    @adapter = AnyCable::RackServer::BroadcastAdapters::HubAdapter.new(@hub, @coder)
  end

  def test_broadcast
    @hub.expect(:broadcast, true, ['stream', { data: :yup }, @coder])
    @adapter.broadcast('stream', { data: :yup })
    assert_mock @hub
  end
end
