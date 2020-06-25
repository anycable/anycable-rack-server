# frozen_string_literal: true

module AnyCable
  module Rack
    class Railtie < ::Rails::Railtie # :nodoc: all
      config.before_configuration do
        config.any_cable_rack = AnyCable::Rack.config
      end

      initializer "anycable.rack.mount", after: "action_cable.routes" do
        config.after_initialize do |app|
          config = app.config.any_cable_rack

          # Only if AnyCable adapter is used
          next unless AnyCable::Rails.enabled?

          server = AnyCable::Rack::Server.new

          app.routes.prepend do
            mount server => config.mount_path

            if AnyCable.config.broadcast_adapter.to_s == "http"
              mount server.broadcast => config.http_broadcast_path
            end
          end

          server.start!
        end
      end
    end
  end
end
