# frozen_string_literal: true

require "anyway_config"

module AnyCable
  module Rack
    class Config < Anyway::Config
      DEFAULT_HEADERS = %w[cookie x-api-token].freeze

      config_name :anycable
      env_prefix "ANYCABLE"

      attr_config mount_path: "/cable",
                  headers: DEFAULT_HEADERS,
                  rpc_addr: "localhost:50051",
                  rpc_client_pool_size: 5,
                  rpc_client_timeout: 5,
                  http_broadcast_path: "/_anycable_rack_broadcast",
                  run_rpc: false
    end
  end
end
