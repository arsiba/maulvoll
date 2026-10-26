require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}", "x-robots-tag" => "noindex, nofollow" }
  config.active_storage.service = :local
  config.assume_ssl = ENV["ASSUME_SSL"] == "true"
  config.force_ssl = true
  config.ssl_options = { hsts: { expires: 1.year, subdomains: true } }
  config.log_tags = [ :request_id ]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "warn")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false
  config.cache_store = :solid_cache_store
  config.active_job.queue_adapter = :solid_queue
  config.solid_queue.connects_to = { database: { writing: :queue } }
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST"), protocol: "https" }
  config.hosts = ENV.fetch("APP_HOST").split(",")
  config.action_cable.allowed_request_origins = ENV.fetch("CABLE_ORIGINS").split(",")
  config.action_cable.allow_same_origin_as_host = false
  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]
end
