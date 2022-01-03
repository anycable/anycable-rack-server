# frozen_string_literal: true

gem "msgpack", "~> 1.4"
require "msgpack"

module AnyCable
  module Rack
    module Coders
      module Msgpack # :nodoc:
        class << self
          def decode(bin)
            MessagePack.unpack(bin)
          end

          def encode(ruby_obj, binary_frame_wrap: true)
            message_packed = MessagePack.pack(ruby_obj)

            return message_packed unless binary_frame_wrap

            BinaryFrame.new(message_packed)
          end
        end
      end
    end
  end
end
