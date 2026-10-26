class SeedTemplates < ApplicationActor
  def call
    TastingPresets.call.presets.each do |preset|
      TastingTemplate.find_or_initialize_by(name: preset.fetch(:name)).update!(preset)
    end
  end
end
