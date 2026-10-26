import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["preset", "singular", "plural", "maximum", "criteria", "awards", "vibes", "rows", "rowTemplate", "award", "vibe"]
  static values = { templates: Array, default: Object }

  connect() {
    this.load(this.defaultValue)
  }

  select() {
    const template = this.templatesValue.find(item => String(item.id) === this.presetTarget.value)
    if (template) this.load(template)
  }

  load(template) {
    this.singularTarget.value = template.product_singular
    this.pluralTarget.value = template.product_plural
    this.maximumTarget.value = template.max_score_per_criterion
    this.rowsTarget.replaceChildren()
    template.criteria_schema.forEach(criterion => this.appendRow(criterion))
    this.awardTargets.forEach(input => { input.value = template.award_titles[input.dataset.key] })
    this.vibeTargets.forEach(input => { input.value = template.vibe_messages[input.dataset.key] })
    this.serialize()
  }

  appendRow(criterion = { key: "", label: "" }) {
    const row = this.rowTemplateTarget.content.firstElementChild.cloneNode(true)
    row.querySelector("[data-criterion-key]").value = criterion.key
    row.querySelector("[data-criterion-label]").value = criterion.label
    this.rowsTarget.appendChild(row)
  }

  add() {
    if (this.rowsTarget.children.length >= 12) return
    this.appendRow()
    this.rowsTarget.lastElementChild.querySelector("input").focus()
    this.serialize()
  }

  remove(event) {
    if (this.rowsTarget.children.length <= 1) return
    event.target.closest("[data-criterion-row]").remove()
    this.serialize()
  }

  serialize() {
    this.criteriaTarget.value = JSON.stringify(Array.from(this.rowsTarget.children).map(row => ({
      key: row.querySelector("[data-criterion-key]").value,
      label: row.querySelector("[data-criterion-label]").value
    })))
    this.awardsTarget.value = JSON.stringify(Object.fromEntries(this.awardTargets.map(input => [input.dataset.key, input.value])))
    this.vibesTarget.value = JSON.stringify(Object.fromEntries(this.vibeTargets.map(input => [input.dataset.key, input.value])))
  }
}
