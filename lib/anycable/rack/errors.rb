# frozen_string_literal: true

module AnyCable
  module Rack
    module Errors
      class HijackNotAvailable < RuntimeError; end
      class MiddlewareSetup < StandardError; end
    end
  end
end
