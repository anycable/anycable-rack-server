# frozen_string_literal: true

module AnyCable
  module RackServer
    module Errors
      class HijackNotAvailable < RuntimeError; end
      class UnknownCommand < StandardError; end
    end
  end
end