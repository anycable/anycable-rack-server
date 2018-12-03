class Anyt::TestChannels::SubscriptionAknowledgementRejectorChannel < ApplicationCable::Channel
  def subscribed
    reject
  end
end
