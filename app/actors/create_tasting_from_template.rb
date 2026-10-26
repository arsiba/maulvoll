class CreateTastingFromTemplate < ApplicationActor
  input :user
  input :attributes
  input :template_id, default: nil
  output :tasting_session

  def call
    deny! unless user
    base = template_id.present? ? TastingTemplate.find(template_id).attributes.slice(*configuration_keys) : TastingPresets.call.presets.first.stringify_keys.slice(*configuration_keys)
    data = attributes.to_h.stringify_keys.slice("title", "date", *configuration_keys)
    %w[criteria_schema award_titles vibe_messages].each do |key|
      data[key] = JSON.parse(data[key]) if data[key].is_a?(String)
    end
    self.tasting_session = user.tasting_sessions.create!(base.merge(data).merge(date: data["date"].presence || Date.current))
  rescue JSON::ParserError
    deny!("Die Konfiguration enthält ungültiges JSON.", 422)
  end

  private

  def configuration_keys
    %w[product_singular product_plural max_score_per_criterion criteria_schema award_titles vibe_messages]
  end
end
