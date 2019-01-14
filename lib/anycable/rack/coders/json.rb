# frozen_string_literal: true

require "json"

module AnyCable
  module Rack
    module Coders
      module JSON # :nodoc:
        class << self
          def decode(json_str)
            ::JSON.parse(json_str)
          end

          def encode(ruby_obj)
            ruby_obj.to_json
          end
        end
      end
    end
  end
end
