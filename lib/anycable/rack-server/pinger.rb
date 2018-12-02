# frozen_string_literal: true

module AnyCable
  module RackServer
    # Sends pings to sockets
    class Pinger
      INTERVAL = 3

      def initialize
        @_sockets = []
        run
      end

      def add(socket)
        @_sockets << socket
      end

      def remove(socket)
        @_sockets.delete(socket)
      end

      def stop
        @_stopped = true
      end

      # rubocop: disable Metrics/MethodLength
      def run
        Thread.new do
          Thread.current.abort_on_exception = true
          loop do
            break if @_stopped

            unless @_sockets.empty?
              msg = ping_message(Time.now.to_i)
              @_sockets.each do |socket|
                socket.transmit(msg)
              end
            end

            sleep(INTERVAL)
          end
        end
      end
      # rubocop: enable Metrics/MethodLength

      private

      def ping_message(time)
        { type: :ping, message: time }.to_json
      end
    end
  end
end
