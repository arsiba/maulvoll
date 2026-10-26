module Host
  class ParticipantsController < ApplicationController
    include TastingAccess
    before_action -> { load_access(:host) }

    def destroy
      ManageTasting.call(tasting_session: @tasting, user: Current.user, operation: :block, participant_token: params[:participant_token])
      redirect_to host_tasting_session_path(@tasting.invite_token), status: :see_other
    end
  end
end
