class CalculateRoundVibe < ApplicationActor
  input :tasting_session
  input :round
  output :vibe

  def call
    deny! unless round.tasting_session_id == tasting_session.id
    deny!("Die Runde läuft noch.", 409) unless tasting_session.final_reveal? || tasting_session.round_vibe? && tasting_session.current_round_id == round.id
    ratings = round.ratings.joins(:participant).where(participants: { blocked: false }).to_a
    average = ratings.empty? ? nil : ratings.sum(&:total_score).fdiv(ratings.size)
    means = tasting_session.criteria_schema.map do |criterion|
      [ criterion["label"], ratings.empty? ? 0 : ratings.sum { |r| r.scores.fetch(criterion["key"]) }.fdiv(ratings.size) ]
    end
    percentage = average ? average.fdiv(tasting_session.max_total) * 100 : 0
    tier = percentage < 40 ? "low" : percentage < 60 ? "medium" : percentage <= 80 ? "high" : "excellent"
    self.vibe = { average_total: average, percentage: percentage, vibe_title: average ? tasting_session.vibe_messages.fetch(tier) : "Noch keine Stimmen auf dem Zettel.", best: ratings.empty? ? nil : means.max_by(&:last), worst: ratings.empty? ? nil : means.min_by(&:last), quotes: ratings.map(&:notes).compact_blank.sample(5) }
  end
end
