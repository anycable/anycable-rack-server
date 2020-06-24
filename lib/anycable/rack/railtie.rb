# frozen_string_literal: true

module AnyCable
  module Rack
    class Railtie < ::Rails::Railtie # :nodoc: all
      class Config < Anyway::Config
        config_name :anycable
        env_prefix "ANYCABLE"

        attr_config mount_path: "/cable",
                    headers: AnyCable::Rack::Server::DEFAULT_HEADERS,
                    rpc_port: 50_051,
                    rpc_host: "localhost",
                    broadcast_adapter: :redis,
                    http_broadcast_secret: nil,
                    http_broadcast_path: "/_anycable_rack_broadcast",
                    run_rpc: false,
                    running_rpc: false
      end

      config.before_configuration do
        config.any_cable_rack = Config.new
      end

      initializer "anycable.rack.mount", after: "action_cable.routes" do
        config.after_initialize do |app|
          config = app.config.any_cable_rack

          # Only if AnyCable adapter is used
          next unless AnyCable::Rails.enabled?

          server = AnyCable::Rack::Server.new(
            headers: config.headers,
            rpc_host: "#{config.rpc_host}:#{config.rpc_port}",
            broadcast_adapter: config.broadcast_adapter,
            http_broadcast_secret: config.http_broadcast_secret,
            http_broadcast_path: config.http_broadcast_path
          )

          app.routes.prepend do
            mount server => config.mount_path

            if config.broadcast_adapter.to_s == "http"
              mount server.broadcast => config.http_broadcast_path
            end
          end

          if config.run_rpc && !config.running_rpc
            AnyCable::Rack::RPCRunner.run(
              rpc_host: "[::]:#{config.rpc_port}",
              root_dir: ::Rails.root.to_s,
              env: {
                "ANYCABLE_RUNNING_RPC" => "true"
              }
            )
          end

          server.start!
        end
      end
    end
  end
end
