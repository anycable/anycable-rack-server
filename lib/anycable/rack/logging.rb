# frozen_string_literal: true

module AnyCable
  module Rack
    module Logging # :nodoc:
      PREFIX = "AnyCableRackServer"

      private

      def log(level, message = nil, logger = AnyCable.logger)
        logger.send(level, PREFIX) { message || yield }
      end
    end
  end
end
