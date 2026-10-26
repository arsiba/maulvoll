module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :connection_key

    def connect
      self.connection_key = SecureRandom.hex(16)
      reject_unauthorized_connection unless host || participant || tv_session
    end

    def authorized_stream?(stream)
      return false unless stream
      if host
        return true if host.tasting_sessions.any? { |t| [ stream_for(t, :host), stream_for(t, :public) ].include?(stream) }
      end
      if participant && !participant.blocked?
        return true if stream == stream_for(participant.tasting_session, :public)
      end
      tv_session && stream == stream_for(tv_session, :public)
    end

    private

    def host
      Session.find_by(id: cookies.signed[:session_id], created_at: 30.days.ago..)&.user
    end

    def participant
      token = cookies.encrypted[:participant_token]
      Participant.find_by(session_token: token) if token.present?
    end

    def tv_session
      token = cookies.encrypted[:tv_token]
      TastingSession.find_by(tv_token: token) if token.present?
    end

    def stream_for(tasting, kind)
      Turbo::StreamsChannel.send(:stream_name_from, [ tasting, kind ])
    end
  end
end
