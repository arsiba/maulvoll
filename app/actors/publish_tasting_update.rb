class PublishTastingUpdate < ApplicationActor
  input :tasting_session

  def call
    Turbo::StreamsChannel.broadcast_refresh_to(tasting_session, :public)
    Turbo::StreamsChannel.broadcast_refresh_to(tasting_session, :host)
  end
end
