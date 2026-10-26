module TastingConfiguration
  extend ActiveSupport::Concern
  included do
    validates :product_singular, :product_plural, presence: true, length: { maximum: 60 }
    validates :max_score_per_criterion, numericality: { only_integer: true, in: 1..10 }
    validate :valid_configuration
  end

  def max_total
    criteria_schema.size * max_score_per_criterion
  end

  private

  def valid_configuration
    valid = criteria_schema.is_a?(Array) && criteria_schema.size.between?(1, 12) && criteria_schema.all? do |criterion|
      criterion.is_a?(Hash) && criterion.keys.sort == %w[key label] && criterion["key"].is_a?(String) && criterion["key"].match?(/\A[a-z][a-z0-9_]{0,29}\z/) && criterion["label"].is_a?(String) && criterion["label"].length.between?(1, 50)
    end
    valid &&= criteria_schema.map { |c| c["key"] }.uniq.size == criteria_schema.size
    errors.add(:criteria_schema, "muss 1–12 eindeutige Kriterien enthalten") unless valid
    { award_titles: %w[best worst weirdest], vibe_messages: %w[low medium high excellent] }.each do |attribute, keys|
      value = public_send(attribute)
      unless value.is_a?(Hash) && value.keys.sort == keys.sort && value.values.all? { |v| v.is_a?(String) && v.length.between?(1, 120) }
        errors.add(attribute, "enthält ungültige Texte")
      end
    end
  end
end
