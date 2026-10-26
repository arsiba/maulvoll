class JoinTastingSession < ApplicationActor
  input :tasting_session
  input :name
  input :participant_token, default: nil
  output :participant

  def call
    tasting_session.with_lock do
      self.participant = tasting_session.participants.find_by(session_token: participant_token) if participant_token.present?
      if participant
        deny!("Du wurdest aus dieser Verkostung entfernt.") if participant.blocked?
      else
        deny!("Die Lobby ist geschlossen.") if tasting_session.entry_locked? || tasting_session.final_reveal?
        self.participant = tasting_session.participants.create!(name: name)
      end
    end
    announce(tasting_session)
  end
end
