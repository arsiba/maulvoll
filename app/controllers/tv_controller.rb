class TvController < ApplicationController
  include TastingAccess
  allow_unauthenticated_access

  def show
    load_access(:tv)
    cookies.encrypted[:tv_token] = { value: @tasting.tv_token, httponly: true, secure: Rails.env.production?, same_site: :lax, expires: 1.day.from_now }
    load_view
  end
end
