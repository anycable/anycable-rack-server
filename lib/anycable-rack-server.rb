# frozen_string_literal: true

require "anycable/rack/config"
require "anycable/rack/server"

module AnyCable
  module Rack
    class << self
      def config
        @config ||= Config.new
      end

      def rpc_server
        return @rpc_server if instance_variable_defined?(:@rpc_server)

        require "anycable/cli"
        @rpc_server = AnyCable::CLI.new(embedded: true)
      end
    end
  end
end

require "anycable/rack/railtie" if defined?(Rails)
