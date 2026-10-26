class Rating < ApplicationRecord
  belongs_to :round
  belongs_to :participant
  validates :participant_id, uniqueness: { scope: :round_id }
  validates :notes, length: { maximum: 280 }
  validate :valid_scores

  private

  def valid_scores
    return unless round && participant
    tasting = round.tasting_session
    errors.add(:participant, "gehört zu einer anderen Verkostung") unless participant.tasting_session_id == tasting.id
    keys = tasting.criteria_schema.map { |c| c["key"] }
    valid = scores.is_a?(Hash) && scores.keys.sort == keys.sort && scores.values.all? { |v| v.is_a?(Integer) && v.between?(1, tasting.max_score_per_criterion) }
    errors.add(:scores, "bitte jedes Kriterium innerhalb der Skala bewerten") unless valid
    errors.add(:total_score, "stimmt nicht mit den Einzelwerten überein") unless valid && total_score == scores.values.sum
  end
end
