CI.run do
  step "Setup", "bin/setup --skip-server"
  step "Style: Ruby", "bin/rubocop"
  step "Tests", "bundle exec rspec"
  step "Multiplayer browser tests", "yarn test:browser"
  step "Autoload", "bin/rails zeitwerk:check"
  step "Security: Gem audit", "bin/bundler-audit"
  step "Security: Yarn vulnerability audit", "yarn audit"
  step "Security: Importmap vulnerability audit", "bin/importmap audit"
  step "Security: Brakeman", "bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error"
end
