# frozen_string_literal: true

# Make sure Anyt is using AnyCable adapter
ActionCable.server.config.cable = {"adapter" => "any_cable"}
