class ManageTasting < ApplicationActor
  input :tasting_session
  input :user
  input :operation
  input :attributes, default: -> { {} }
  input :number, default: nil
  input :participant_token, default: nil

  def call
    owner!(tasting_session, user)
    tasting_session.with_lock do
      case operation
      when :lock
        tasting_session.update!(entry_locked: !tasting_session.entry_locked?)
      when :block
        tasting_session.participants.find_by!(session_token: participant_token).update!(blocked: true)
        tasting_session.touch
      when :round_create, :round_update, :round_destroy
        deny!("Runden können nur in der Lobby bearbeitet werden.", 409) unless tasting_session.lobby?
        if operation == :round_create
          deny!("Maximal 100 Runden erlaubt.", 422) if tasting_session.rounds.count >= 100
          tasting_session.rounds.create!(attributes)
        else
          round = tasting_session.rounds.find_by!(number: number)
          operation == :round_update ? round.update!(attributes) : round.destroy!
        end
        tasting_session.touch
      else
        deny!("Ungültige Aktion.", 422)
      end
    end
    announce(tasting_session)
  end
end
