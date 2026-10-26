require "rails_helper"

RSpec.describe CalculateFinalAwards do
  let(:tasting) { create(:tasting_session) }

  it "uses the last criterion to break winner ties and ones to break loser ties" do
    first = create(:round, tasting_session: tasting, number: 1)
    second = create(:round, tasting_session: tasting, number: 2)
    keys = tasting.criteria_schema.map { |c| c["key"] }
    [ [ first, [ 5, 3, 3, 3, 3, 1 ] ], [ second, [ 3, 3, 3, 3, 3, 3 ] ] ].each do |round, values|
      participant = create(:participant, tasting_session: tasting)
      Rating.create!(round: round, participant: participant, scores: keys.zip(values).to_h, total_score: values.sum)
    end
    tasting.update!(status: :final_reveal)
    result = described_class.call(tasting_session: tasting)
    expect(result.awards[:best][:round]).to eq(second)
    expect(result.awards[:worst][:round]).to eq(first)
    expect(result.awards[:weirdest][:round]).to eq(first)
    expect(result.awards[:weirdest][:weirdness_index]).to eq(8)
  end

  it "adds population standard deviation and twice the first-to-last score gap" do
    round = create(:round, tasting_session: tasting)
    [ [ 5, 5, 5, 5, 5, 1 ], [ 1, 1, 1, 1, 1, 5 ] ].each do |values|
      person = create(:participant, tasting_session: tasting)
      Rating.create!(round: round, participant: person, scores: tasting.criteria_schema.map { |c| c["key"] }.zip(values).to_h, total_score: values.sum)
    end
    tasting.update!(status: :final_reveal)
    expect(described_class.call(tasting_session: tasting).awards[:weirdest][:weirdness_index]).to eq(16)
  end
end
