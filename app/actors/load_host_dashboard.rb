class LoadHostDashboard < ApplicationActor
  input :user
  output :tastings
  output :templates
  output :default_configuration

  def call
    self.tastings = user.tasting_sessions.order(created_at: :desc)
    self.templates = TastingTemplate.order(:name)
    self.default_configuration = TastingPresets.call.presets.first
  end
end
