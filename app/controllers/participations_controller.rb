class ParticipationsController < ApplicationController
  include TastingAccess
  allow_unauthenticated_access
  before_action -> { load_access(:join) }
  invisible_captcha only: :create, honeypot: :nickname_confirmation, on_spam: :reject_spam, on_timestamp_spam: :reject_spam

  def new
  end

  def create
    result = JoinTastingSession.call(tasting_session: @tasting, name: params[:name], participant_token: cookies.encrypted[:participant_token])
    cookies.encrypted[:participant_token] = { value: result.participant.session_token, httponly: true, secure: Rails.env.production?, same_site: :lax, expires: 7.days.from_now }
    redirect_to tasting_path(@tasting.invite_token), status: :see_other
  end

  private

  def reject_spam
    render "shared/error", locals: { message: "Beitritt abgelehnt. Bitte öffne den Einladungslink erneut und versuche es nach einigen Sekunden." }, status: :unprocessable_entity
  end
end
