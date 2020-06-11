# frozen_string_literal: true

require "minitest/autorun"
require "anycable-rack-server"
require "securerandom"
require "set"

class TestHub < Minitest::Test
  attr_reader :coder,
    :hub,
    :channel,
    :msg,
    :stream

  def setup
    @coder = AnyCable::Rack::Coders::JSON
    @hub = AnyCable::Rack::Hub.new
    @channel = "channel"
    @msg = {data: :test}.to_json
    @stream = "stream"
  end

  def test_add_subscriber
    setup_helper_data
    hub.add_subscriber(stream, @socket, channel)

    assert_equal [@socket], hub.sockets.keys
    assert_equal [stream], hub.streams.keys
    assert_equal [{channel => @set}], hub.streams.values
  end

  def test_broadcast
    socket = Minitest::Mock.new
    3.times { socket.expect(:hash, SecureRandom.hex.to_i) }
    socket.expect(:transmit, true, [{identifier: channel, message: coder.decode(msg)}.to_json])
    hub.add_subscriber(stream, socket, channel)
    hub.broadcast(stream, msg, coder)

    assert_mock socket
  end

  def test_remove_subscriber
    setup_helper_data

    hub.add_subscriber(stream, @socket, channel)
    hub.remove_subscriber(stream, @socket, channel)

    assert_equal [], hub.sockets.keys
    assert_equal [], hub.streams.keys
    assert_equal [], hub.streams.values
  end

  def test_remove_subscriber_multiple_streams
    setup_helper_data

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel)
    hub.remove_subscriber(stream, @socket, channel)

    assert_equal [@socket], hub.sockets.keys
    assert_equal [@stream2], hub.streams.keys
    assert_equal [{channel => @set}], hub.streams.values
  end

  def test_remove_channel
    setup_helper_data

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel)
    hub.remove_channel(@socket, channel)

    assert_equal [], hub.sockets.keys
    assert_equal [], hub.streams.keys
    assert_equal [], hub.streams.values
  end

  def test_remove_channel_multiple_streams
    setup_helper_data

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel)
    hub.remove_channel(@socket, channel)

    assert_equal [], hub.sockets.keys
    assert_equal [], hub.streams.keys
    assert_equal [], hub.streams.values
  end

  def test_remove_channel_multiple_channels
    setup_helper_data
    channel2 = "channel2"

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(stream, @socket, channel2)
    hub.remove_channel(@socket, channel)

    assert_equal [@socket], hub.sockets.keys
    assert_equal [stream], hub.streams.keys
    assert_equal [{channel2 => @set}], hub.streams.values
  end

  def test_remove_socket
    setup_helper_data

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel)
    hub.remove_socket(@socket)

    assert_equal [], hub.sockets.keys
    assert_equal [], hub.streams.keys
    assert_equal [], hub.streams.values
  end

  def test_remove_socket_multiple_streams_and_channels
    setup_helper_data
    channel2 = "channel2"

    hub.add_subscriber(stream, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel)
    hub.add_subscriber(@stream2, @socket, channel2)
    hub.remove_socket(@socket)

    assert_equal [], hub.sockets.keys
    assert_equal [], hub.streams.keys
    assert_equal [], hub.streams.values
  end

  private

  def setup_helper_data
    @socket = "mock"
    @stream2 = "stream2"
    @set = Set.new
    @set << @socket
  end
end
