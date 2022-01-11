# frozen_string_literal: true

gem "google-protobuf", "~> 3.19", ">= 3.19.1"
require_relative "./proto/message_pb"
require_relative "./msgpack"

module AnyCable
  module Rack
    module Coders
      module Protobuf # :nodoc:
        class << self
          def decode(bin)
            decoded_message = ActionCable::Message.decode(bin).to_h

            decoded_message[:command] = decoded_message[:command].to_s
            if decoded_message[:message].present?
              decoded_message[:message] = Msgpack.decode(decoded_message[:message])
            end

            decoded_message.each_with_object({}) { |(k, v), h| h[k.to_s] = v }
          end

          def encode(ruby_obj)
            message = ruby_obj.delete(:message)

            data = ActionCable::Message.new(ruby_obj)

            if message
              data.message = Msgpack.encode(message, binary_frame_wrap: false)
            end

            BinaryFrame.new(ActionCable::Message.encode(data))
          end
        end
      end
    end
  end
end
