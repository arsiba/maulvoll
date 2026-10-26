abort("Browser fixtures require the test environment") unless Rails.env.test?

if ARGV.first == "cleanup"
  User.find_by!(email_address: ARGV.fetch(1)).destroy!
else
  password = SecureRandom.hex(20)
  user = User.create!(email_address: "browser-#{SecureRandom.hex(12)}@example.test", password: password)
  tasting = CreateTastingFromTemplate.call(user: user, attributes: { title: "Mehrere Gäste am Tisch" }).tasting_session
  6.times do |index|
    ManageTasting.call(tasting_session: tasting, user: user, operation: :round_create, attributes: { number: index + 1, secret_identity: "Geheime Browser-Testmarke #{index + 1}" })
  end
  puts({ email: user.email_address, password: password, invite: tasting.invite_token, tv: tasting.tv_token }.to_json)
end
