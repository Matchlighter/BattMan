class ThingChannel < ApplicationCable::Channel
  def subscribed
    @thing = Thing.new(id: params[:thing_id]) # Use a dummy thing to avoid a DB hit
    @thing.readonly!
    stream_for @thing
  end

  def unsubscribed
  end
end
