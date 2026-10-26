module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session
  end

  def require_authentication
    resume_session || redirect_to(new_session_path)
  end

  def resume_session
    Current.session ||= Session.find_by(id: cookies.signed[:session_id], created_at: 30.days.ago..)
  end

  def establish_session(record)
    reset_session
    Current.session = record
    cookies.signed[:session_id] = { value: record.id, httponly: true, secure: Rails.env.production?, same_site: :lax, expires: 30.days.from_now }
  end
end
