require "rails_helper"

RSpec.describe "Public security", type: :request do
  let(:tasting) { create(:tasting_session) }
  let!(:round) { create(:round, tasting_session: tasting, number: 1) }

  def join(tasting, name = "<script>alert(1)</script>")
    post join_path(tasting.invite_token), params: { name: name }
  end

  def login(user)
    post session_path, params: { email_address: user.email_address, password: "Verkostung-Sicher-2026!" }
  end

  it "renders the Turbo refresh settings needed to preserve scroll and stream connections" do
    get root_path
    document = Nokogiri::HTML(response.body)
    expect(document.at_css('meta[name="turbo-refresh-method"]')["content"]).to eq("morph")
    expect(document.at_css('meta[name="turbo-refresh-scroll"]')["content"]).to eq("preserve")
  end

  it "has a neutral landing page and guards all management routes" do
    get root_path
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(tasting.title, tasting.invite_token, round.secret_identity)
    expect(response.headers["X-Robots-Tag"]).to include("noindex")
    get host_tasting_sessions_path
    expect(response).to redirect_to(new_session_path)
    post advance_host_tasting_session_path(tasting.invite_token)
    expect(response).to redirect_to(new_session_path)
    post "/users", params: { email_address: "attacker@example.test" }
    expect(response).to have_http_status(:not_found)
  end

  it "does not reveal secrets on join, TV, controller or vibe before final reveal" do
    get join_path(tasting.invite_token)
    expect(response.body).not_to include(round.secret_identity, tasting.tv_token)
    get tv_path(tasting.tv_token)
    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include(round.secret_identity)
    join(tasting, "Lisa")
    expect(response).to redirect_to(tasting_path(tasting.invite_token))
    %i[voting round_vibe].each do |status|
      tasting.update!(status: status, current_round: round)
      get tasting_path(tasting.invite_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(round.secret_identity, tasting.tv_token)
      get tv_path(tasting.tv_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).not_to include(round.secret_identity)
    end
    tasting.update!(status: :final_reveal)
    get tasting_path(tasting.invite_token)
    expect(response.body).to include(round.secret_identity)
  end

  it "escapes participant names and notes and denies blocked or foreign cookies" do
    join(tasting)
    get tv_path(tasting.tv_token)
    expect(response.body).to include("&lt;script&gt;")
    expect(response.body).not_to include("<script>alert(1)</script>")
    other = create(:tasting_session)
    get tasting_path(other.invite_token)
    expect(response).to have_http_status(:forbidden)
    tasting.update!(status: :voting, current_round: round)
    post ratings_path(tasting.invite_token), params: { round_number: 1, scores: tasting.criteria_schema.to_h { |c| [ c["key"], 5 ] }, notes: "<script>bad()</script>" }
    expect(response).to have_http_status(:see_other)
    tasting.update!(status: :round_vibe)
    get tv_path(tasting.tv_token)
    expect(response.body).to include("&lt;script&gt;bad()&lt;/script&gt;")
    tasting.participants.first.update!(blocked: true)
    get tasting_path(tasting.invite_token)
    expect(response).to have_http_status(:forbidden)
  end

  it "rejects invalid capabilities, early exports, unauthenticated ratings and honeypots" do
    get tv_path("invalid")
    expect(response).to have_http_status(:not_found)
    get tasting_path(tasting.invite_token)
    expect(response).to have_http_status(:forbidden)
    post ratings_path(tasting.invite_token)
    expect(response).to have_http_status(:forbidden)
    post join_path(tasting.invite_token), params: { name: "Bot", nickname_confirmation: "spam" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(tasting.participants.count).to eq(0)
    join(tasting, "Lisa")
    get export_tasting_path(tasting.invite_token)
    expect(response).to have_http_status(:conflict)
  end

  it "renders personal exports only after reveal" do
    join(tasting, "Lisa")
    tasting.update!(status: :final_reveal, current_round: round)
    get export_tasting_path(tasting.invite_token)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include("Drucken", round.secret_identity)
    get export_tasting_path(tasting.invite_token, format: :csv)
    expect(response.media_type).to eq("text/csv")
    expect(response.headers["Content-Disposition"]).to include("attachment")
  end

  it "isolates hosts and renders the real host dashboard" do
    login(create(:user))
    get host_tasting_session_path(tasting.invite_token)
    expect(response).to have_http_status(:not_found)
    delete session_path
    login(tasting.user)
    get host_tasting_session_path(tasting.invite_token)
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(round.secret_identity)
    patch lock_host_tasting_session_path(tasting.invite_token)
    expect(tasting.reload).to be_entry_locked
    get new_host_tasting_session_path
    expect(response).to have_http_status(:ok)
    post host_tasting_session_rounds_path(tasting.invite_token), params: { round: { number: 2, secret_identity: "Andere Marke", tags: [ "Bio", "" ] } }
    expect(response).to have_http_status(:see_other)
    expect(tasting.rounds.count).to eq(2)
  end

  it "throttles login, joining and ratings per IP" do
    6.times { post session_path, params: { email_address: "none@example.test", password: "wrong" } }
    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"].to_i).to be_positive
    11.times { post join_path("invalid"), params: { name: "Bot" } }
    expect(response).to have_http_status(:too_many_requests)
    21.times { post ratings_path("invalid") }
    expect(response).to have_http_status(:too_many_requests)
  end

  it "enforces CSRF protection for browser mutations" do
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    post join_path(tasting.invite_token), params: { name: "Angriff" }
    expect(response).to have_http_status(:unprocessable_content)
    expect(tasting.participants.count).to eq(0)
  ensure
    ActionController::Base.allow_forgery_protection = original
  end
end
