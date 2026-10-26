FactoryBot.define do
  factory :user do
    sequence(:email_address) { |n| "host#{n}@example.test" }
    password { "Verkostung-Sicher-2026!" }
  end

  factory :tasting_session do
    association :user
    title { Faker::Food.dish }
    date { Date.current }
    product_singular { "Maultasche" }
    product_plural { "Maultaschen" }
    max_score_per_criterion { 5 }
    criteria_schema { TastingPresets.call.presets.first.fetch(:criteria_schema) }
    award_titles { TastingPresets.call.presets.first.fetch(:award_titles) }
    vibe_messages { TastingPresets.call.presets.first.fetch(:vibe_messages) }
  end

  factory :round do
    association :tasting_session
    sequence(:number)
    secret_identity { "STRENG_GEHEIME_MARKE" }
    context_info { "Gebraten" }
    tags { [ "Bio" ] }
  end

  factory :participant do
    association :tasting_session
    name { Faker::Name.first_name.first(25) }
  end
end
