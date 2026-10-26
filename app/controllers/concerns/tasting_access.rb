module TastingAccess
  extend ActiveSupport::Concern

  private

  def load_access(mode)
    result = ResolveTastingAccess.call(token: params[:invite_token] || params[:tasting_session_invite_token] || params[:tv_token], mode: mode, participant_token: cookies.encrypted[:participant_token], user: Current.user)
    @tasting = result.tasting_session
    @participant = result.participant
  end

  def load_view
    @view = BuildTastingView.call(tasting_session: @tasting, participant: @participant).view
  end
end
