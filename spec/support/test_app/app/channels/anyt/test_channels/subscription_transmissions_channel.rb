class Anyt::TestChannels::SubscriptionTransmissionsChannel < ApplicationCable::Channel
  def subscribed
    transmit('hello')
    transmit('world')
  end
end
