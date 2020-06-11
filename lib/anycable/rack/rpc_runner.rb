# frozen_string_literal: true

require "anycable"
require "anycable/rack/logging"

require "childprocess"

module AnyCable
  module Rack
    # Runs AnyCable CLI in a separate process
    module RPCRunner
      class << self
        include Logging

        attr_accessor :process

        def run(root_dir:, command_args: [], rpc_host: "[::]:50051", env: {})
          return if running?

          command_args << "--rpc-host=\"#{rpc_host}\""

          command = "bundle exec anycable #{command_args.join(" ")}"

          log(:info, "Running AnyCable (from #{root_dir}): #{command}")

          @process = ChildProcess.build(*command.split(/\s+/))

          process.io.inherit! if AnyCable.config.debug?
          process.detach = true
          process.environment.merge!(env)
          process.start

          log(:debug) { "AnyCable PID: #{pid}" }

          at_exit { stop }
        end

        def stop
          return unless running?

          log(:debug) { "Terminate PID: #{pid}" }
          process.stop
        end

        def pid
          process&.pid
        end

        def running?
          process&.alive?
        end
      end
    end
  end
end
