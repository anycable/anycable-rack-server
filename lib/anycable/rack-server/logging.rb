# frozen_string_literal: true

module AnyCable
  module RackServer
    module Logging # :nodoc:
      PREFIX = 'AnycableRackServer'

      private

      def log(level, message = nil, logger = AnyCable.logger)
        logger.send(level, PREFIX) { message || yield }
      end
    end
  end
end
