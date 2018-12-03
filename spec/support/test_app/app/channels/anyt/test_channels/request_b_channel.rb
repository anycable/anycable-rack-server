class Anyt::TestChannels::RequestBChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'b'
  end

  def unsubscribed
    ActionCable.server.broadcast('b', data: 'user left')
  end
end
