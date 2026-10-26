class EndHostSession < ApplicationActor
  input :session

  def call
    session.destroy!
  end
end
