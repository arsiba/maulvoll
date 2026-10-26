class CalculateFinalAwards < ApplicationActor
  input :tasting_session
  output :ranking
  output :awards

  def call
    deny!("Die Marken bleiben noch geheim.", 409) unless tasting_session.final_reveal?
    first_key = tasting_session.criteria_schema.first.fetch("key")
    last_key = tasting_session.criteria_schema.last.fetch("key")
    entries = tasting_session.rounds.includes(ratings: :participant).map do |round|
      ratings = round.ratings.reject { |r| r.participant.blocked? }
      count = ratings.size
      average = count.positive? ? ratings.sum(&:total_score).fdiv(count) : nil
      deviation = count.positive? ? Math.sqrt(ratings.sum { |r| (r.total_score - average)**2 }.fdiv(count)) : 0
      gap = count.positive? ? ratings.sum { |r| (r.scores.fetch(first_key) - r.scores.fetch(last_key)).abs }.fdiv(count) : 0
      { round: round, average_total: average, count: count, last_average: count.positive? ? ratings.sum { |r| r.scores.fetch(last_key) }.fdiv(count) : 0,
        ones: ratings.sum { |r| r.scores.values.count(1) }, weirdness_index: deviation + 2 * gap }
    end
    eligible = entries.select { |entry| entry[:count].positive? }
    self.ranking = entries.sort_by { |e| [ e[:average_total] ? 0 : 1, -(e[:average_total] || 0), -e[:last_average], e[:round].number ] }
    self.awards = {
      best: eligible.max_by { |e| [ e[:average_total], e[:last_average], -e[:round].number ] },
      worst: eligible.min_by { |e| [ e[:average_total], -e[:ones], e[:round].number ] },
      weirdest: eligible.max_by { |e| [ e[:weirdness_index], -e[:round].number ] }
    }
  end
end
