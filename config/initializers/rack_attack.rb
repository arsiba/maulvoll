Rack::Attack.cache.store = if Rails.env.production?
  ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("RATE_LIMIT_REDIS_URL"), namespace: "maulvoll:rate_limits", error_handler: ->(method:, returning:, exception:) { raise exception })
else
  ActiveSupport::Cache::MemoryStore.new
end

Rack::Attack.throttle("login/ip", limit: 5, period: 60) { |req| req.ip if req.post? && req.path == "/session" }
Rack::Attack.throttle("join/ip", limit: 10, period: 60) { |req| req.ip if req.post? && req.path.match?(%r{\A/join/[^/]+\z}) }
Rack::Attack.throttle("ratings/ip", limit: 20, period: 60) { |req| req.ip if req.post? && req.path.match?(%r{\A/tasting/[^/]+/ratings\z}) }
Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"][:period] - Time.now.to_i % request.env["rack.attack.match_data"][:period]).to_s
  [ 429, { "content-type" => "text/plain; charset=utf-8", "retry-after" => retry_after, "cache-control" => "no-store", "x-robots-tag" => "noindex, nofollow" }, [ "Zu viele Versuche. Bitte warte einen Moment." ] ]
end
Rails.application.config.middleware.use Rack::Attack
