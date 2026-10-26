class RatingsController < ApplicationController
  include TastingAccess
  allow_unauthenticated_access
  before_action -> { load_access(:participant) }

  def create
    SubmitRating.call(tasting_session: @tasting, participant: @participant, round_number: params[:round_number], scores: params.fetch(:scores, ActionController::Parameters.new).permit(*@tasting.criteria_schema.pluck("key")).to_h, notes: params[:notes])
    redirect_to tasting_path(@tasting.invite_token), notice: "Bewertung gespeichert. Bis zum Rundenende kannst du sie ändern.", status: :see_other
  end
end
