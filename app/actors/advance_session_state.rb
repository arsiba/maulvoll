class AdvanceSessionState < ApplicationActor
  input :tasting_session
  input :user
  input :expected_version

  def call
    owner!(tasting_session, user)
    tasting_session.with_lock do
      deny!("Die Phase wurde bereits geändert. Bitte aktualisieren.", 409) unless tasting_session.updated_at.iso8601(6) == expected_version
      case tasting_session.status
      when "lobby"
        first = tasting_session.rounds.first
        deny!("Lege zuerst eine Runde an.", 422) unless first
        tasting_session.update!(status: :voting, current_round: first)
      when "voting"
        tasting_session.update!(status: :round_vibe)
      when "round_vibe"
        following = tasting_session.rounds.where("number > ?", tasting_session.current_round.number).first
        tasting_session.update!(status: following ? :voting : :final_reveal, current_round: following || tasting_session.current_round)
      else
        deny!("Die Verkostung ist bereits beendet.", 409)
      end
    end
    announce(tasting_session)
  end
end
