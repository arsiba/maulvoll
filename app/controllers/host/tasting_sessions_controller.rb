module Host
  class TastingSessionsController < ApplicationController
    include TastingAccess
    before_action -> { load_access(:host) }, only: %i[show advance lock]

    def index
      @dashboard = LoadHostDashboard.call(user: Current.user)
    end

    def new
      @dashboard = LoadHostDashboard.call(user: Current.user)
    end

    def create
      result = CreateTastingFromTemplate.call(user: Current.user, template_id: params[:template_id], attributes: params.require(:tasting_session).permit(:title, :date, :product_singular, :product_plural, :max_score_per_criterion, :criteria_schema, :award_titles, :vibe_messages).to_h.reject { |_, value| value.blank? })
      redirect_to host_tasting_session_path(result.tasting_session.invite_token), status: :see_other
    end

    def show
      load_view
    end

    def advance
      AdvanceSessionState.call(tasting_session: @tasting, user: Current.user, expected_version: params[:version])
      redirect_to host_tasting_session_path(@tasting.invite_token), status: :see_other
    end

    def lock
      ManageTasting.call(tasting_session: @tasting, user: Current.user, operation: :lock)
      redirect_to host_tasting_session_path(@tasting.invite_token), status: :see_other
    end
  end
end
