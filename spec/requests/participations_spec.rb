require "rails_helper"

RSpec.describe "Participant identities", type: :request do
  let(:tasting) { create(:tasting_session) }

  it "keeps independent browser identities and renders every active guest" do
    names = %w[Anna Ben Clara]
    browsers = names.map do |name|
      browser = ActionDispatch::Integration::Session.new(Rails.application)
      browser.post join_path(tasting.invite_token), params: { name: name }
      expect(browser.response).to have_http_status(:see_other)
      browser
    end
    expect(tasting.participants.pluck(:name)).to match_array(names)
    expect(tasting.participants.pluck(:session_token).uniq.size).to eq(3)
    browsers.zip(names).each do |browser, name|
      browser.get tasting_path(tasting.invite_token)
      document = Nokogiri::HTML(browser.response.body)
      expect(document.css(".participant-badges .stamp").map(&:text)).to match_array(names)
      expect(document.at_css(".controller-sheet > div .stamp").text).to include(name)
    end
    get tv_path(tasting.tv_token)
    document = Nokogiri::HTML(response.body)
    expect(document.css(".participant-badges .stamp").map(&:text)).to match_array(names)
  end

  it "shows the existing identity on rejoin instead of silently accepting a different name" do
    post join_path(tasting.invite_token), params: { name: "Anna" }
    get join_path(tasting.invite_token)
    expect(response.body).to include("Willkommen zurück, Anna!", "Weitere Tabs verwenden denselben Teilnehmer.")
    expect(Nokogiri::HTML(response.body).at_css('input[name="name"]')).to be_nil
    tasting.update!(entry_locked: true)
    expect { post join_path(tasting.invite_token), params: { name: "Ben" } }.not_to change(Participant, :count)
    follow_redirect!
    expect(response.body).to include("Anna ist am Tisch")
    expect(tasting.participants.pluck(:name)).to eq([ "Anna" ])
  end

  it "rejects blocked identities before offering re-entry" do
    post join_path(tasting.invite_token), params: { name: "Anna" }
    tasting.participants.first.update!(blocked: true)
    get join_path(tasting.invite_token)
    expect(response).to have_http_status(:forbidden)
  end
end
