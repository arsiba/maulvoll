class ApplicationController < ActionController::Base
  include Authentication
  before_action :private_response
  rescue_from DomainError, with: :domain_error
  rescue_from ActiveRecord::RecordInvalid, with: :invalid_record
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def private_response
    response.set_header("X-Robots-Tag", "noindex, nofollow, noarchive")
    response.set_header("Cache-Control", "no-store, private")
    response.set_header("Referrer-Policy", "no-referrer")
    response.set_header("Permissions-Policy", "camera=(), microphone=(), geolocation=()")
  end

  def domain_error(error)
    render "shared/error", locals: { message: error.message }, status: error.status
  end

  def invalid_record(error)
    render "shared/error", locals: { message: error.record.errors.full_messages.join(" · ") }, status: :unprocessable_entity
  end

  def not_found
    render "shared/error", locals: { message: "Dieser Link ist nicht verfügbar." }, status: :not_found
  end
end
