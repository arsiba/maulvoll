require "rails_helper"

RSpec.describe "Tasting actors" do
  let(:tasting) { create(:tasting_session) }
  let(:host) { tasting.user }
  let(:round) { create(:round, tasting_session: tasting, number: 1) }
  let(:participant) { create(:participant, tasting_session: tasting) }
  let(:scores) { tasting.criteria_schema.to_h { |c| [ c["key"], 4 ] } }

  def advance(tasting, user = tasting.user, version = tasting.reload.updated_at.iso8601(6))
    AdvanceSessionState.call(tasting_session: tasting, user: user, expected_version: version)
  end

  def vote(tasting, participant, round, scores, notes = nil)
    SubmitRating.call(tasting_session: tasting, participant: participant, round_number: round.number, scores: scores, notes: notes)
  end

  it "creates an independent preset copy and tokens with at least 256 bits of entropy" do
    template = TastingTemplate.create!(TastingPresets.call.presets.first.merge(name: "Vorlage für unabhängige Verkostungen"))
    result = CreateTastingFromTemplate.call(user: host, template_id: template.id, attributes: { title: "Abend" }).tasting_session
    expect(result.max_total).to eq(30)
    expect(result.invite_token.length).to eq(44)
    expect(result.tv_token).not_to eq(result.invite_token)
    template.update!(product_singular: "Neu")
    expect(result.reload.product_singular).to eq("Maultasche")
  end

  it "advances all rounds and refuses strangers and stale phase transitions" do
    round
    create(:round, tasting_session: tasting, number: 2)
    expect { advance(tasting, create(:user)) }.to raise_error(DomainError)
    old_version = tasting.reload.updated_at.iso8601(6)
    advance(tasting)
    expect(tasting).to be_voting
    expect { advance(tasting, host, old_version) }.to raise_error(DomainError, /bereits geändert/)
    advance(tasting)
    expect(tasting).to be_round_vibe
    advance(tasting)
    expect(tasting.current_round.number).to eq(2)
    advance(tasting)
    advance(tasting)
    expect(tasting).to be_final_reveal
    expect { advance(tasting) }.to raise_error(DomainError)
  end

  it "refuses to start without rounds or edit rounds after starting" do
    expect { advance(tasting) }.to raise_error(DomainError, /Runde/)
    round
    advance(tasting)
    expect { ManageTasting.call(tasting_session: tasting, user: host, operation: :round_destroy, number: 1) }.to raise_error(DomainError)
  end

  it "allows late joins and existing guests in locked lobbies, but never blocked guests" do
    round
    advance(tasting)
    joined = JoinTastingSession.call(tasting_session: tasting, name: "Später Gast").participant
    tasting.update!(entry_locked: true)
    expect(JoinTastingSession.call(tasting_session: tasting, name: "", participant_token: joined.session_token).participant).to eq(joined)
    expect { JoinTastingSession.call(tasting_session: tasting, name: "Fremd") }.to raise_error(DomainError)
    ManageTasting.call(tasting_session: tasting, user: host, operation: :block, participant_token: joined.session_token)
    expect { JoinTastingSession.call(tasting_session: tasting, name: "", participant_token: joined.session_token) }.to raise_error(DomainError)
  end

  it "validates complete integer scores and upserts one vote per round" do
    round
    advance(tasting)
    vote(tasting, participant, round, scores, "Sehr ordentlich")
    expect(participant.ratings.first.total_score).to eq(24)
    expect { vote(tasting, participant, round, scores.transform_values { 5 }) }.not_to change(Rating, :count)
    [ {}, scores.merge("fremd" => 5), scores.merge("optik" => 0), scores.merge("optik" => 6), scores.merge("optik" => "2.5"), scores.merge("optik" => [ 2 ]), scores.except("optik") ].each do |invalid|
      expect { vote(tasting, participant, round, invalid) }.to raise_error { |error| expect([ DomainError, ActiveRecord::RecordInvalid ]).to include(error.class) }
    end
    expect { vote(tasting, participant, round, scores, "a" * 281) }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it "refuses foreign participants, blocked participants, stale rounds and closed phases" do
    round
    expect { vote(tasting, participant, round, scores) }.to raise_error(DomainError)
    advance(tasting)
    foreign = create(:participant)
    expect { vote(tasting, foreign, round, scores) }.to raise_error(DomainError)
    participant.update!(blocked: true)
    expect { vote(tasting, participant, round, scores) }.to raise_error(DomainError)
    participant.update!(blocked: false)
    expect { SubmitRating.call(tasting_session: tasting, participant: participant, round_number: 99, scores: scores) }.to raise_error(DomainError)
    advance(tasting)
    expect { vote(tasting, participant, round, scores) }.to raise_error(DomainError)
  end

  it "calculates anonymous round vibes and excludes blocked votes" do
    round
    advance(tasting)
    vote(tasting, participant, round, scores, "Schmeckt!")
    blocked = create(:participant, tasting_session: tasting)
    vote(tasting, blocked, round, scores.transform_values { 1 })
    blocked.update!(blocked: true)
    advance(tasting)
    vibe = CalculateRoundVibe.call(tasting_session: tasting, round: round).vibe
    expect(vibe[:average_total]).to eq(24)
    expect(vibe[:quotes]).to eq([ "Schmeckt!" ])
    expect(vibe.to_json).not_to include(round.secret_identity)
    expect { CalculateFinalAwards.call(tasting_session: tasting) }.to raise_error(DomainError)
  end

  it "handles no votes without inventing winners" do
    round
    tasting.update!(status: :final_reveal, current_round: round)
    result = CalculateFinalAwards.call(tasting_session: tasting)
    expect(result.awards.values).to all(be_nil)
    expect(result.ranking.first[:average_total]).to be_nil
  end

  it "keeps broadcasts free of identities, notes, cookies and signed private streams" do
    expect(Turbo::StreamsChannel).to receive(:broadcast_refresh_to).with(tasting, :public)
    expect(Turbo::StreamsChannel).to receive(:broadcast_refresh_to).with(tasting, :host)
    PublishTastingUpdate.call(tasting_session: tasting)
  end

  it "guards exports and neutralizes spreadsheet formulas" do
    round
    advance(tasting)
    vote(tasting, participant, round, scores, "=HYPERLINK(42)")
    expect { ExportTasting.call(tasting_session: tasting, participant: participant) }.to raise_error(DomainError)
    advance(tasting)
    advance(tasting)
    csv = ExportTasting.call(tasting_session: tasting, participant: participant).csv
    expect(csv).to include("'=HYPERLINK(42)", round.secret_identity, "Ø Gruppe")
    expect { ExportTasting.call(tasting_session: tasting, participant: create(:participant)) }.to raise_error(DomainError)
  end

  it "seeds three templates and six rounds without resetting existing data" do
    user = create(:user)
    result = SeedTastings.call(email: user.email_address)
    expect(TastingTemplate.count).to eq(3)
    expect(result.tasting_session.rounds.count).to eq(6)
    expect(result.tasting_session.max_total).to eq(30)
    expect { SeedTastings.call(email: user.email_address) }.not_to change(TastingSession, :count)
    expect { SeedTastings.call(email: "new@example.test") }.to raise_error(DomainError)
  end

  it "rejects invalid schemas, overlong names and attempts to inject ownership" do
    other = create(:user)
    result = CreateTastingFromTemplate.call(user: host, attributes: { title: "Sicher", user_id: other.id, status: :final_reveal, invite_token: "injected" }).tasting_session
    expect(result.user).to eq(host)
    expect(result).to be_lobby
    expect(result.invite_token).not_to eq("injected")
    expect { JoinTastingSession.call(tasting_session: tasting, name: "a" * 26) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { CreateTastingFromTemplate.call(user: host, attributes: { title: "Ungültig", criteria_schema: [ { "key" => "<script>", "label" => "Test" } ] }) }.to raise_error(ActiveRecord::RecordInvalid)
    expect { CreateTastingFromTemplate.call(user: host, attributes: { title: "Ungültig", criteria_schema: "[bad" }) }.to raise_error(DomainError)
  end
end
