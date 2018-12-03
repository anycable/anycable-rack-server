class Anyt::TestChannels::SubscriptionPerformMethodsChannel < ApplicationCable::Channel
  def tick
    transmit('tock')
  end

  def echo(data)
    transmit(response: data['text'])
  end
end
