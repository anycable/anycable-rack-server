# frozen_string_literal: true

$LOAD_PATH.push File.expand_path("../../../lib", __dir__)

require "anyt/dummy/application"

Rails.application.config.root = File.join(__dir__, "..")

# Rails.application.config.log_level = :debug

require "anyt/tests"

ActionCable.server.config.cable = {"adapter" => "any_cable"}

require "anycable-rack-server"

# Load channels from tests
Anyt::Tests.load_all_tests

Rails.application.initialize!
