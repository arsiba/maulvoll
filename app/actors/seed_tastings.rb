class SeedTastings < ApplicationActor
  input :email
  input :password, default: nil
  output :user
  output :tasting_session

  def call
    self.user = User.find_or_initialize_by(email_address: email.to_s.strip.downcase)
    if user.new_record?
      deny!("ADMIN_PASSWORD mit mindestens 14 Zeichen setzen.", 422) if password.blank?
      user.password = password
      user.save!
    end
    SeedTemplates.call
    self.tasting_session = user.tasting_sessions.find_by(title: "Das große Maultaschen-Tasting")
    return if tasting_session
    ActiveRecord::Base.transaction do
      self.tasting_session = CreateTastingFromTemplate.call(user: user, template_id: TastingTemplate.find_by!(name: "Schwäbisches Maultaschen-Tasting").id, attributes: { title: "Das große Maultaschen-Tasting" }).tasting_session
      [
        [ "Bürger · Traditionelle Maultaschen", "In der Brühe", [ "Klassisch" ] ],
        [ "Bürger · Gemüse-Maultaschen", "Gebraten", [ "Vegetarisch" ] ],
        [ "Settele · Schwäbische Maultaschen", "In der Brühe", [ "Klassisch" ] ],
        [ "Bürger · Vegane Maultaschen", "Gebraten", [ "Vegan" ] ],
        [ "ALDI · Schwäbische Maultaschen", "In der Brühe", [ "Discounter" ] ],
        [ "Hausgemachte Maultaschen", "Geschmälzt", [ "Handgemacht" ] ]
      ].each_with_index do |(identity, context, tags), index|
        ManageTasting.call(tasting_session: tasting_session, user: user, operation: :round_create, attributes: { number: index + 1, secret_identity: identity, context_info: context, tags: tags })
      end
    end
  end
end
