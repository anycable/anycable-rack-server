# frozen_string_literal: true

require "anycable"
require "anycable/rack/logging"

$stdout.sync = true

module AnyCable
  module Rack
    # Runs AnyCable CLI in a separate process
    module RPCRunner
      class << self
        include Logging

        attr_accessor :running, :pid

        def run(root_dir:, command_args: [], rpc_host: "[::]:50051", env: {})
          return if @running

          command_args << "--rpc-host=\"#{rpc_host}\""

          command = "bundle exec anycable #{command_args.join(" ")}"

          log(:info, "Running AnyCable (from #{root_dir}): #{command}")

          out = AnyCable.config.debug? ? STDOUT : IO::NULL

          @pid = Dir.chdir(root_dir) do
            Process.spawn(
              env,
              command,
              out: out,
              err: out
            )
          end

          log(:debug) { "AnyCable PID: #{pid}" }

          @running = true

          at_exit { stop }
        end

        def stop
          return unless running

          log(:debug) { "Terminate PID: #{pid}" }

          Process.kill("SIGKILL", pid)

          @running = false
        end

        def running?
          running == true
        end
      end
    end
  end
end
