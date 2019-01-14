# frozen_string_literal: true

require "anycable/rack/logging"

module AnyCable
  module Rack
    # Socket wrapper
    class Socket
      include Logging
      attr_reader :version, :socket

      def initialize(env, socket, version)
        log(:debug, "WebSocket version #{version}")
        @env = env
        @socket = socket
        @version = version

        @_open_handlers    = []
        @_message_handlers = []
        @_close_handlers   = []
        @_error_handlers   = []
        @_active           = true
      end

      def transmit(data, type: :text)
        frame = WebSocket::Frame::Outgoing::Server.new(
          version: version,
          data: data,
          type: type
        )
        socket.write(frame.to_s)
      rescue IOError, Errno::EPIPE, Errno::ETIMEDOUT => e
        log(:error, "Socket send failed: #{e}")
        close
      end

      def request
        @request ||= ::Rack::Request.new(@env)
      end

      def onopen(&block)
        @_open_handlers << block
      end

      def onmessage(&block)
        @_message_handlers << block
      end

      def onclose(&block)
        @_close_handlers << block
      end

      def onerror(&block)
        @_error_handlers << block
      end

      def listen
        keepalive
        Thread.new do
          Thread.current.abort_on_exception = true
          begin
            @_open_handlers.each(&:call)
            each_frame do |data|
              @_message_handlers.each do |handler|
                begin
                  handler.call(data)
                rescue => e # rubocop: disable Style/RescueStandardError
                  log(:error, "Socket receive failed: #{e}")
                  @_error_handlers.each { |eh| eh.call(e, data) }
                  close
                end
              end
            end
          ensure
            close
          end
        end
      end

      def close
        return unless @_active

        @_close_handlers.each(&:call)
        close!

        @_active = false
      end

      def closed?
        socket.closed?
      end

      private

      def close!
        if socket.respond_to?(:closed?)
          close_socket unless @socket.closed?
        else
          close_socket
        end
      end

      def close_socket
        frame = WebSocket::Frame::Outgoing::Server.new(version: version, type: :close, code: 1000)
        socket.write(frame.to_s) if frame.supported?
        socket.close
      rescue IOError, Errno::EPIPE, Errno::ETIMEDOUT
        # already closed
      end

      def keepalive
        thread = Thread.new do
          Thread.current.abort_on_exception = true
          loop do
            sleep 5
            time = Time.now.to_i
            transmit({ message: time, type: :ping }.to_json)
          end
        end

        onclose do
          thread.kill
        end
      end

      def each_frame
        framebuffer = WebSocket::Frame::Incoming::Server.new(version: version)
        while IO.select([socket])
          if socket.respond_to?(:recvfrom)
            data, _addrinfo = socket.recvfrom(2000)
          else
            data = socket.readpartial(2000)
            _addrinfo = socket.peeraddr
          end

          break if data.empty?

          framebuffer << data

          while frame = framebuffer.next
            case frame.type
            when :close
              return
            when :text, :binary
              yield frame.data
            end
          end
        end
      rescue Errno::EHOSTUNREACH, Errno::ETIMEDOUT, Errno::ECONNRESET, IOError, Errno::EBADF => e
        log(:error, "Socket frame error: #{e}")
        nil # client disconnected or timed out
      end
    end
  end
end
