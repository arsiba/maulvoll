require "rails_helper"

RSpec.describe Turbo::StreamsChannel, type: :channel do
  let(:tasting) { create(:tasting_session) }
  let(:signature) { described_class.signed_stream_name([ tasting, :public ]) }

  it "rejects even a valid stolen stream signature without matching cookie authorization" do
    stub_connection
    connection.define_singleton_method(:authorized_stream?) { |_stream| false }
    subscribe signed_stream_name: signature
    expect(subscription).to be_rejected
  end

  it "accepts a signed stream for an authorized connection" do
    stub_connection
    connection.define_singleton_method(:authorized_stream?) { |_stream| true }
    subscribe signed_stream_name: signature
    expect(subscription).to be_confirmed
  end

  it "rejects a forged signature" do
    stub_connection
    connection.define_singleton_method(:authorized_stream?) { |_stream| false }
    subscribe signed_stream_name: "forged"
    expect(subscription).to be_rejected
  end
end
