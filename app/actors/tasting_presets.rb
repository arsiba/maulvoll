class TastingPresets < ApplicationActor
  output :presets

  def call
    self.presets = [
      configuration("Schwäbisches Maultaschen-Tasting", "Maultasche", "Maultaschen", %w[Optik Teig Füllung Saftigkeit Würzung Geschmack], %w[optik teig fuellung saftigkeit wuerzung geschmack]),
      configuration("Craft-Bier-Tasting", "Bier", "Biere", %w[Optik Schaum Duft Mundgefühl Balance Geschmack], %w[optik schaum duft mundgefuehl balance geschmack]),
      configuration("Kaffee-Cupping", "Kaffee", "Kaffees", %w[Duft Säure Körper Süße Balance Geschmack], %w[duft saeure koerper suesse balance geschmack])
    ]
  end

  private

  def configuration(name, singular, plural, labels, keys)
    { name: name, product_singular: singular, product_plural: plural, max_score_per_criterion: 5,
      criteria_schema: keys.zip(labels).map { |key, label| { "key" => key, "label" => label } },
      award_titles: { "best" => "Goldene #{singular}", "worst" => "Ultra Reudig", "weirdest" => "Was zur #{singular} ist das??" },
      vibe_messages: { "low" => "Da hilft auch kein Senf mehr.", "medium" => "Kann man machen. Muss man aber nicht.", "high" => "Noch eine Portion, bitte!", "excellent" => "Heiligs Blechle. Ist das gut!" } }
  end
end
