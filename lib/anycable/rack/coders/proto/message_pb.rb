# frozen_string_literal: true

require "google/protobuf"

Google::Protobuf::DescriptorPool.generated_pool.build do
  add_message "action_cable.Message" do
    optional :type, :enum, 1, "action_cable.Type"
    optional :command, :enum, 2, "action_cable.Command"
    optional :identifier, :string, 3
    optional :data, :string, 4
    optional :message, :bytes, 5
    optional :reason, :string, 6
    optional :reconnect, :bool, 7
  end
  add_enum "action_cable.Type" do
    value :no_type, 0
    value :welcome, 1
    value :disconnect, 2
    value :ping, 3
    value :confirm_subscription, 4
    value :reject_subscription, 5
  end
  add_enum "action_cable.Command" do
    value :unknown_command, 0
    value :subscribe, 1
    value :unsubscribe, 2
    value :message, 3
  end
end

module ActionCable
  Message = Google::Protobuf::DescriptorPool.generated_pool.lookup("action_cable.Message").msgclass
  Type = Google::Protobuf::DescriptorPool.generated_pool.lookup("action_cable.Type").enummodule
  Command = Google::Protobuf::DescriptorPool.generated_pool.lookup("action_cable.Command").enummodule
end
