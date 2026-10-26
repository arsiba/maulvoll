require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  it "rejects anonymous sockets" do
    expect { connect "/cable" }.to have_rejected_connection
  end

  it "authorizes only the participant session public stream and rejects blocks" do
    participant = create(:participant)
    cookies.encrypted[:participant_token] = participant.session_token
    connect "/cable"
    stream = Turbo::StreamsChannel.send(:stream_name_from, [ participant.tasting_session, :public ])
    host_stream = Turbo::StreamsChannel.send(:stream_name_from, [ participant.tasting_session, :host ])
    foreign_stream = Turbo::StreamsChannel.send(:stream_name_from, [ create(:tasting_session), :public ])
    expect(connection.authorized_stream?(stream)).to be_truthy
    expect(connection.authorized_stream?(host_stream)).to be_falsey
    expect(connection.authorized_stream?(foreign_stream)).to be_falsey
    participant.update!(blocked: true)
    expect(connection.authorized_stream?(stream)).to be_falsey
  end
end
