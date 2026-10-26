module AuthorizedTurboStreams
  def subscribed
    if connection.authorized_stream?(verified_stream_name_from_params)
      super
    else
      reject
    end
  end
end

Rails.application.config.to_prepare do
  Turbo::StreamsChannel.prepend(AuthorizedTurboStreams) unless Turbo::StreamsChannel < AuthorizedTurboStreams
end
