class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]

  def new
  end

  def create
    result = AuthenticateHost.call(email_address: params[:email_address], password: params[:password], user_agent: request.user_agent, ip_address: request.remote_ip)
    establish_session(result.session)
    redirect_to host_tasting_sessions_path, status: :see_other
  end

  def destroy
    EndHostSession.call(session: Current.session)
    reset_session
    cookies.delete(:session_id)
    Current.reset
    redirect_to new_session_path, status: :see_other
  end
end
