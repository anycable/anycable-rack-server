# frozen_string_literal: true

require "anycable/rack/version"
require "anycable/rack/config"
require "anycable/rack/server"

module AnyCable
  module Rack
    class << self
      def config
        @config ||= Config.new
      end
    end
  end
end

require "anycable/rack/railtie" if defined?(Rails)
