# frozen_string_literal: true

require "json"

module AnyCable
  module Rack
    module BroadcastSubscribers
      class BaseSubscriber
        include Logging

        attr_reader :hub, :coder

        def initialize(hub:, coder:, **options)
          @hub = hub
          @coder = coder
        end

        def start
          # no-op
        end

        def stop
          # no-op
        end

        private

        def handle_message(msg)
          log(:debug) { "Received pub/sub message: #{msg}" }

          data = JSON.parse(msg)
          if data["stream"]
            hub.broadcast(data["stream"], data["data"], coder)
          elsif data["command"] == "disconnect"
            hub.disconnect(data["payload"]["identifier"], data["payload"]["reconnect"], coder)
          end
        end
      end
    end
  end
end
