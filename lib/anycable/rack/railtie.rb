# frozen_string_literal: true

require "anyway_config"

module AnyCable
  module Rack
    class Railtie < ::Rails::Railtie # :nodoc: all
      class Config < Anyway::Config
        config_name :anycable_rack
        env_prefix "ANYCABLE_RACK"

        attr_config mount_path: "/cable",
                    headers: AnyCable::Rack::Server::DEFAULT_HEADERS,
                    rpc_port: 50_051,
                    rpc_host: "localhost",
                    run_rpc: false,
                    running_rpc: false

        private :running_rpc=
      end

      config.before_configuration do
        config.any_cable_rack = Config.new
      end

      initializer "anycable.rack.mount", after: "action_cable.routes" do
        config.after_initialize do |app|
          config = app.config.any_cable_rack

          # Only if AnyCable adapter is used
          next unless ::ActionCable.server.config.cable&.fetch("adapter", nil) == "any_cable"

          server = AnyCable::Rack::Server.new(
            headers: config.headers,
            rpc_host: "#{config.rpc_host}:#{config.rpc_port}"
          )

          app.routes.prepend do
            mount server => config.mount_path
          end

          if config.run_rpc && !config.running_rpc
            AnyCable::Rack::RPCRunner.run(
              rpc_host: "[::]:#{config.rpc_port}",
              root_dir: ::Rails.root.to_s,
              env: {
                "ANYCABLE_RACK_RUNNING_RPC" => "true"
              }
            )
          end

          server.start!
        end
      end
    end
  end
end
