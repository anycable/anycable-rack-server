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

          def encode(ruby_obj)
            BinaryFrame.new(MessagePack.pack(ruby_obj))
          end
        end
      end
    end
  end
end
