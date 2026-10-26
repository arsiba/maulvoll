class BuildTastingView < ApplicationActor
  input :tasting_session
  input :participant, default: nil
  output :view

  def call
    active = tasting_session.participants.active
    round = tasting_session.current_round
    ratings = round ? round.ratings.joins(:participant).where(participants: { blocked: false }) : Rating.none
    final = tasting_session.final_reveal? ? CalculateFinalAwards.call(tasting_session: tasting_session) : nil
    self.view = { tasting: tasting_session, round: round, participants: active.order(:created_at).to_a,
      voted: ratings.count, count: active.count,
      personal_rating: participant && round ? participant.ratings.find_by(round: round) : nil,
      personal_ratings: participant ? participant.ratings.index_by(&:round_id) : {},
      vibe: tasting_session.round_vibe? ? CalculateRoundVibe.call(tasting_session: tasting_session, round: round).vibe : nil,
      ranking: final&.ranking, awards: final&.awards }
  end
end
