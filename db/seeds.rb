if ENV["ADMIN_EMAIL"].present?
  SeedTastings.call(email: ENV.fetch("ADMIN_EMAIL"), password: ENV["ADMIN_PASSWORD"])
else
  SeedTemplates.call
end
