class Anyt::TestChannels::MultipleStreamsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'a'
    stream_from 'b'
  end
end
