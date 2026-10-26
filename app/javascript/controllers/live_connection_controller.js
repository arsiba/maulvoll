import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.connected = false
    this.observer = new MutationObserver(() => this.sync())
    this.observer.observe(this.element, { attributes: true, attributeFilter: ["connected"] })
    this.sync()
  }

  disconnect() {
    this.observer.disconnect()
  }

  sync() {
    const connected = this.element.hasAttribute("connected")
    if (connected && !this.connected) window.Turbo.session.refresh(window.location.href)
    this.connected = connected
  }
}
