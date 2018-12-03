class Anyt::TestChannels::StreamsWithManyClientsChannel< ApplicationCable::Channel
  def subscribed
    stream_from 'a'
  end
end
