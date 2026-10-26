require "csv"

class ExportTasting < ApplicationActor
  input :tasting_session
  input :participant
  output :csv

  def call
    deny! unless participant.tasting_session_id == tasting_session.id && !participant.blocked?
    final = CalculateFinalAwards.call(tasting_session: tasting_session)
    personal = participant.ratings.index_by(&:round_id)
    self.csv = CSV.generate(col_sep: ";", encoding: "UTF-8") do |table|
      table << [ safe(tasting_session.title), safe(participant.name), tasting_session.date.iso8601 ]
      final.awards.each { |key, entry| table << [ safe(tasting_session.award_titles.fetch(key.to_s)), safe(entry&.dig(:round)&.secret_identity) ] }
      table << [ "Nr.", "Name / Marke", "Zubereitung / Info", *tasting_session.criteria_schema.map { |c| safe(c["label"]) }, "Gesamt / #{tasting_session.max_total}", "Ø Gruppe", "Sonst noch was?" ]
      final.ranking.sort_by { |entry| entry[:round].number }.each do |entry|
        round = entry[:round]
        rating = personal[round.id]
        table << [ round.number, safe(round.secret_identity), safe(round.context_info), *tasting_session.criteria_schema.map { |c| rating&.scores&.fetch(c["key"], nil) }, rating&.total_score, entry[:average_total]&.round(2), safe(rating&.notes) ]
      end
    end
  end

  private

  def safe(value)
    text = value.to_s
    text.match?(/\A[[:space:]]*[=+@\-\t\r\n]/) ? "'#{text}" : text
  end
end
