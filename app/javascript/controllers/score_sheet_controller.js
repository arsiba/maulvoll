import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["total", "score"]

  connect() {
    this.update()
  }

  update() {
    this.totalTarget.textContent = this.scoreTargets.filter(input => input.checked).reduce((sum, input) => sum + Number(input.value), 0)
  }
}
