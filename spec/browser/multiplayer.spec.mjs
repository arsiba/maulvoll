import { test as base, expect } from "@playwright/test"
import { execFileSync } from "node:child_process"

function fixture(...args) {
  return execFileSync("bin/rails", ["runner", "spec/browser/support/fixture.rb", ...args], {
    env: { ...process.env, RAILS_ENV: "test" },
    encoding: "utf8",
    stdio: ["ignore", "pipe", "pipe"]
  })
}

const test = base.extend({
  tasting: async ({}, use) => {
    const tasting = JSON.parse(fixture())
    try {
      await use(tasting)
    } finally {
      fixture("cleanup", tasting.email)
    }
  }
})

test.afterEach(async ({ browser }) => {
  await Promise.all(browser.contexts().map(context => context.close()))
})

async function openDevice(browser, baseURL, path, viewport = { width: 1280, height: 720 }) {
  const context = await browser.newContext({ baseURL, viewport })
  await context.route("https://fonts.googleapis.com/**", route => route.abort())
  await context.route("https://fonts.gstatic.com/**", route => route.abort())
  const page = await context.newPage()
  await page.goto(path)
  await page.waitForLoadState("networkidle")
  return page
}

async function openHost(browser, baseURL, tasting) {
  const page = await openDevice(browser, baseURL, "/session/new")
  await page.locator("#email_address").fill(tasting.email)
  await page.locator("#password").fill(tasting.password)
  await page.getByRole("button", { name: "Aufschließen →" }).click()
  await page.waitForURL("**/host/tasting_sessions")
  await page.goto(`/host/tasting_sessions/${tasting.invite}`)
  await page.waitForLoadState("networkidle")
  page.on("dialog", dialog => dialog.accept())
  return page
}

async function guest(browser, baseURL, tasting, name) {
  const page = await openDevice(browser, baseURL, `/join/${tasting.invite}`, { width: 390, height: 640 })
  await page.getByLabel("Wie heißt du am Tisch?").fill(name)
  return page
}

async function join(page, tasting) {
  await page.getByRole("button", { name: "Bin dabei / Wieder einsteigen →" }).click()
  await page.waitForURL(`**/tasting/${tasting.invite}`)
}

async function holdNextRefresh(page) {
  let release
  let captured
  let first = true
  const gate = new Promise(resolve => { release = resolve })
  const received = new Promise(resolve => { captured = resolve })
  await page.route(page.url(), async route => {
    const response = await route.fetch()
    if (first) {
      first = false
      captured()
      await gate
    }
    await route.fulfill({ response })
  })
  return { received, release }
}

async function observeRefreshes(page) {
  await page.evaluate(() => {
    window.receivedRefreshes = 0
    document.addEventListener("message", event => {
      if (event.target.matches("turbo-cable-stream-source") && event.data.includes('action="refresh"')) window.receivedRefreshes += 1
    }, true)
  })
}

async function names(page, selector) {
  return (await page.locator(selector).allTextContents()).map(name => name.trim()).sort()
}

test("all guests reach the TV and host even when joins overlap an in-flight refresh", async ({ browser, baseURL, tasting }) => {
  const host = await openHost(browser, baseURL, tasting)
  const tv = await openDevice(browser, baseURL, `/tv/${tasting.tv}`)
  const guests = await Promise.all(["Anna", "Ben", "Clara"].map(name => guest(browser, baseURL, tasting, name)))
  await host.evaluate(() => window.scrollTo(0, 900))
  await tv.evaluate(() => window.scrollTo(0, 200))
  const hostScroll = await host.evaluate(() => scrollY)
  const tvScroll = await tv.evaluate(() => scrollY)
  await Promise.all([observeRefreshes(host), observeRefreshes(tv)])
  const held = await Promise.all([holdNextRefresh(host), holdNextRefresh(tv)])
  try {
    await join(guests[0], tasting)
    await Promise.all(held.map(refresh => refresh.received))
    await Promise.all(guests.slice(1).map(page => join(page, tasting)))
    await expect.poll(() => tv.evaluate(() => window.receivedRefreshes)).toBeGreaterThanOrEqual(3)
    await expect.poll(() => host.evaluate(() => window.receivedRefreshes)).toBeGreaterThanOrEqual(3)
  } finally {
    held.forEach(refresh => refresh.release())
  }
  await expect.poll(() => names(tv, ".participant-badges .stamp")).toEqual(["Anna", "Ben", "Clara"])
  await expect.poll(() => names(host, ".participant-row > span")).toEqual(["Anna", "Ben", "Clara"])
  await expect(tv.locator(".counter")).toContainText("3")
  expect(await host.evaluate(() => scrollY)).toBe(hostScroll)
  expect(await tv.evaluate(() => scrollY)).toBe(tvScroll)
  await Promise.all([host.waitForLoadState("networkidle"), tv.waitForLoadState("networkidle")])
  const requests = []
  tv.on("request", request => { if (request.url() === tv.url()) requests.push(request) })
  await tv.waitForTimeout(500)
  expect(requests).toHaveLength(0)
  for (const page of [host, tv, ...guests]) await page.context().close()
})

test("separate guests can vote while live updates preserve another guest's unfinished sheet", async ({ browser, baseURL, tasting }) => {
  const host = await openHost(browser, baseURL, tasting)
  const tv = await openDevice(browser, baseURL, `/tv/${tasting.tv}`)
  const dora = await guest(browser, baseURL, tasting, "Dora")
  const emil = await guest(browser, baseURL, tasting, "Emil")
  await Promise.all([join(dora, tasting), join(emil, tasting)])
  await expect.poll(() => names(tv, ".participant-badges .stamp")).toEqual(["Dora", "Emil"])
  host.removeAllListeners("dialog")
  host.once("dialog", dialog => dialog.dismiss())
  await host.getByRole("button", { name: "Erste Runde starten →" }).click()
  await host.getByRole("button", { name: "Lobby schließen", exact: true }).click()
  await expect(tv.getByText("Die Lobby ist geschlossen.")).toBeVisible()
  await host.getByRole("button", { name: "Lobby öffnen", exact: true }).click()
  await expect(host.getByRole("button", { name: "Lobby schließen", exact: true })).toBeVisible()
  host.on("dialog", dialog => dialog.accept())
  await host.getByRole("button", { name: "Erste Runde starten →" }).click()
  const keys = ["optik", "teig", "fuellung", "saftigkeit", "wuerzung", "geschmack"]
  await expect(dora.locator("#notes")).toBeVisible()
  await expect(emil.locator("#notes")).toBeVisible()
  for (const key of keys) await dora.locator(`label[for="score_${key}_4"]`).click()
  await dora.locator("#notes").fill("Doras ungespeicherter Zettel")
  await dora.evaluate(() => window.scrollTo(0, 700))
  const position = await dora.evaluate(() => scrollY)
  for (const key of keys) await emil.locator(`label[for="score_${key}_5"]`).click()
  await emil.getByRole("button", { name: "Zettel abgeben →" }).click()
  await expect(tv.getByText("1 von 2 haben abgestimmt")).toBeVisible()
  await dora.waitForLoadState("networkidle")
  await expect(dora.locator("#notes")).toHaveValue("Doras ungespeicherter Zettel")
  await expect(dora.locator('[data-score-sheet-target="total"]')).toHaveText("24")
  expect(await dora.evaluate(() => scrollY)).toBe(position)
  expect(await dora.content()).not.toContain("Geheime Browser-Testmarke")
  await dora.getByRole("button", { name: "Zettel abgeben →" }).click()
  await expect(tv.getByText("2 von 2 haben abgestimmt")).toBeVisible()
  for (const page of [host, tv, dora, emil]) await page.context().close()
})
