class TastingSessionsController < ApplicationController
  include TastingAccess
  allow_unauthenticated_access
  before_action -> { load_access(:participant) }

  def show
    load_view
  end

  def export
    result = ExportTasting.call(tasting_session: @tasting, participant: @participant)
    respond_to do |format|
      format.html { load_view }
      format.csv { send_data "\uFEFF#{result.csv}", filename: "maulvoll-#{@tasting.date}.csv", type: "text/csv; charset=utf-8", disposition: :attachment }
    end
  end
end
