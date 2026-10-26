import { test, expect } from "@playwright/test"

test("loads local fonts without contacting third-party servers", async ({ page, context, baseURL }) => {
  const origin = new URL(baseURL).origin
  const externalRequests = []
  const fontResponses = []
  await context.route("**/*", async route => {
    const url = new URL(route.request().url())
    if (["http:", "https:"].includes(url.protocol) && url.origin !== origin) {
      externalRequests.push(url.href)
      await route.abort()
    } else {
      await route.continue()
    }
  })
  page.on("response", response => {
    if (response.request().resourceType() === "font") fontResponses.push({ url: response.url(), status: response.status() })
  })
  await page.goto("/")
  const loaded = await page.evaluate(async () => {
    const text = "ÄÖÜ äöü ß ẞ Č Ž €"
    return Promise.all(["Kalam", "Space Mono"].flatMap(family => [400, 700].map(async weight => {
      const fonts = await document.fonts.load(`${weight} 16px "${family}"`, text)
      return { family, weight, loaded: fonts.length > 0 && fonts.every(font => font.status === "loaded") }
    })))
  })
  expect(loaded).toHaveLength(4)
  expect(loaded.every(font => font.loaded)).toBe(true)
  expect(fontResponses).toHaveLength(8)
  expect(fontResponses.every(font => new URL(font.url).origin === origin && font.status === 200)).toBe(true)
  expect(externalRequests).toEqual([])
  await expect(page.locator('link[rel="preconnect"]')).toHaveCount(0)
})
