class ApplicationActor < Actor
  def deny!(message = "Zugriff verweigert.", status = 403)
    raise DomainError.new(message, status)
  end

  def owner!(tasting, user)
    deny! unless user && tasting.user_id == user.id
  end

  def announce(tasting)
    PublishTastingUpdate.call(tasting_session: tasting)
  end
end
