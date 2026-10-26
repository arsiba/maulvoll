class SubmitRating < ApplicationActor
  input :tasting_session
  input :participant
  input :round_number
  input :scores
  input :notes, default: nil
  output :rating

  def call
    tasting_session.with_lock do
      participant.reload
      deny! if participant.blocked? || participant.tasting_session_id != tasting_session.id
      round = tasting_session.current_round
      deny!("Diese Runde nimmt keine Bewertungen an.", 409) unless tasting_session.voting? && round && round.number.to_s == round_number.to_s
      values = scores.to_h.stringify_keys
      deny!("Bitte nur ganze Zahlen abgeben.", 422) unless values.values.all? { |v| v.is_a?(Integer) || v.is_a?(String) && v.match?(/\A[1-9][0-9]?\z/) }
      values.transform_values!(&:to_i)
      self.rating = Rating.find_or_initialize_by(round: round, participant: participant)
      rating.update!(scores: values, total_score: values.values.sum, notes: notes)
    end
    announce(tasting_session)
  end
end
