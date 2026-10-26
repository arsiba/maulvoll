module Host
  class RoundsController < ApplicationController
    include TastingAccess
    before_action -> { load_access(:host) }

    def create
      manage(:round_create)
    end

    def update
      manage(:round_update)
    end

    def destroy
      manage(:round_destroy)
    end

    private

    def manage(operation)
      attributes = operation == :round_destroy ? {} : params.require(:round).permit(:number, :secret_identity, :context_info, tags: []).to_h
      attributes["tags"] = Array(attributes["tags"]).compact_blank unless operation == :round_destroy
      ManageTasting.call(tasting_session: @tasting, user: Current.user, operation: operation, number: params[:number], attributes: attributes)
      redirect_to host_tasting_session_path(@tasting.invite_token), status: :see_other
    end
  end
end
