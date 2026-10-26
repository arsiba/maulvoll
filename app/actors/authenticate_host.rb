class AuthenticateHost < ApplicationActor
  input :email_address
  input :password
  input :user_agent
  input :ip_address
  output :session

  def call
    user = User.authenticate_by(email_address: email_address.to_s, password: password.to_s)
    deny!("E-Mail oder Passwort ist ungültig.", 422) unless user
    self.session = user.sessions.create!(user_agent: user_agent.to_s.first(500), ip_address: ip_address)
  end
end
