class Anyt::TestChannels::RequestAChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'a'
  end

  def unsubscribed
    ActionCable.server.broadcast('a', data: "user left#{params[:id].presence}")
  end
end
