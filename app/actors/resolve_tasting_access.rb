class ResolveTastingAccess < ApplicationActor
  input :token
  input :mode
  input :participant_token, default: nil
  input :user, default: nil
  output :tasting_session
  output :participant, default: nil

  def call
    self.tasting_session = case mode
    when :host then user&.tasting_sessions&.find_by!(invite_token: token)
    when :tv then TastingSession.find_by!(tv_token: token)
    else TastingSession.find_by!(invite_token: token)
    end
    deny!("Nicht gefunden.", 404) unless tasting_session
    return unless mode == :participant
    self.participant = tasting_session.participants.find_by(session_token: participant_token) if participant_token.present?
    deny!("Bitte über den Einladungslink beitreten.", 403) unless participant && !participant.blocked?
  end
end
