# frozen_string_literal: true

module AnyCable
  module RackServer
    PROTOCOLS = ['actioncable-v1-json', 'actioncable-unsupported'].freeze
  end
end

require 'anycable/rack-server/hub'
require 'anycable/rack-server/pinger'
require 'anycable/rack-server/middleware'
require 'anycable/rack-server/broadcast_adapters/hub_adapter'
require 'anycable/rack-server/coders/json'
