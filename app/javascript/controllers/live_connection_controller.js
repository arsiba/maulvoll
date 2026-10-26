import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.connected = false
    this.pendingRefreshUrl = null
    this.receive = this.receive.bind(this)
    this.afterNavigation = () => {
      clearTimeout(this.refreshTimer)
      this.refreshTimer = setTimeout(() => this.flush(), 0)
    }
    this.element.addEventListener("message", this.receive, true)
    document.addEventListener("turbo:load", this.afterNavigation)
    document.addEventListener("turbo:submit-end", this.afterNavigation)
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(this.element, { attributes: true, attributeFilter: ["connected"] })
    this.sync()
  }

  disconnect() {
    this.observer.disconnect()
    this.element.removeEventListener("message", this.receive, true)
    document.removeEventListener("turbo:load", this.afterNavigation)
    document.removeEventListener("turbo:submit-end", this.afterNavigation)
    clearTimeout(this.refreshTimer)
    this.pendingRefreshUrl = null
  }

  receive(event) {
    if (!this.busy) return
    const message = new DOMParser().parseFromString(event.data, "text/html")
    if (!message.querySelector('turbo-stream[action="refresh"]')) return
    event.stopImmediatePropagation()
    this.pendingRefreshUrl = window.location.href
  }

  sync() {
    const connected = this.element.hasAttribute("connected")
    if (connected && !this.connected) {
      this.pendingRefreshUrl = window.location.href
      this.flush()
    }
    this.connected = connected
  }

  flush() {
    if (!this.pendingRefreshUrl || this.busy) return
    const url = this.pendingRefreshUrl
    this.pendingRefreshUrl = null
    if (url === window.location.href) window.Turbo.session.refresh(url, { method: "morph", scroll: "preserve" })
  }

  get busy() {
    const navigator = window.Turbo.navigator
    return navigator.currentVisit || navigator.formSubmission && ["requesting", "waiting", "receiving", "stopping"].includes(navigator.formSubmission.state)
  }
}
