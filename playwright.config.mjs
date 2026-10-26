import { defineConfig } from "@playwright/test"

export default defineConfig({
  testDir: "./spec/browser",
  workers: 1,
  timeout: 30_000,
  use: {
    baseURL: "http://127.0.0.1:3101",
    browserName: "chromium",
    launchOptions: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH ? { executablePath: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH } : {},
    trace: "retain-on-failure"
  },
  webServer: {
    command: "RAILS_ENV=test bin/rails server -b 127.0.0.1 -p 3101",
    url: "http://127.0.0.1:3101/up",
    reuseExistingServer: false,
    timeout: 60_000
  }
})
