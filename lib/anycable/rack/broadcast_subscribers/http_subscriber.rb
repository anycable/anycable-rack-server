# frozen_string_literal: true

require "json"

module AnyCable
  module Rack
    module BroadcastSubscribers
      # HTTP Pub/Sub subscriber
      class HTTPSubscriber < BaseSubscriber
        attr_reader :token, :path

        def initialize(**options)
          super
          @token = options[:token]
          @path = options[:path]
        end

        def start
          log(:info) { "Accepting pub/sub request at #{path}" }
        end

        def call(env)
          req = ::Rack::Request.new(env)

          return invalid_request unless req.post?

          if token && req.get_header("HTTP_AUTHORIZATION") != "Bearer #{token}"
            return invalid_request(401)
          end

          handle_message req.body.read

          [201, {"Content-Type" => "text/plain"}, ["OK"]]
        end

        private

        def invalid_request(code = 422)
          [code, {"Content-Type" => "text/plain"}, ["Invalid request"]]
        end
      end
    end
  end
end
