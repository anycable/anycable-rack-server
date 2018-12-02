# frozen_string_literal: true

module AnyCable
  module RackServer
    module BroadcastAdapters
      class HubAdapter
        attr_reader :hub, :coder
        def initialize(hub, coder)
          @hub = hub
          @coder = coder
        end

        def broadcast(stream, message)
          hub.broadcast(stream, JSON.parse(message), coder)
        end
      end
    end
  end
end
