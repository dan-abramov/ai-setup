import { Controller } from "@hotwired/stimulus"

const MAX_LENGTH = 100
const CONTENT_PATTERN = /^(?![^\p{L}\p{N}_]*$).{1,100}$/u

export default class extends Controller {
  static targets = [
    "skillInput",
    "topicInput",
    "skillError",
    "topicError",
    "submitButton",
    "submitLabel"
  ]

  connect() {
    this.submitDefaultText = this.submitLabelTarget.textContent.trim()
    this.loadingText = this.element.dataset.loadingText || "Генерация..."
    this.formSubmitted = this.initialErrorsPresent()
    this.state = "EMPTY"

    this.recalculate()
  }

  onInput() {
    if (this.state === "LOADING") {
      return
    }

    this.recalculate()
  }

  submit(event) {
    if (this.state === "LOADING") {
      event.preventDefault()
      return
    }

    this.formSubmitted = true
    this.recalculate()

    if (this.state !== "READY") {
      event.preventDefault()
      return
    }

    this.state = "LOADING"
    this.applyState()
  }

  recalculate() {
    const skill = this.evaluateField(this.skillInputTarget.value, {
      blank: "E001",
      tooLong: "E002",
      invalid: "E003"
    })
    const topic = this.evaluateField(this.topicInputTarget.value, {
      blank: "E004",
      tooLong: "E005",
      invalid: "E006"
    })

    this.skillErrorTarget.textContent = skill.error || ""
    this.topicErrorTarget.textContent = topic.error || ""

    if (skill.error || topic.error) {
      this.state = "ERROR"
    } else if (skill.empty || topic.empty) {
      this.state = "EMPTY"
    } else {
      this.state = "READY"
    }

    this.applyState()
  }

  evaluateField(value, codes) {
    const normalizedValue = this.normalized(value)

    if (!normalizedValue) {
      return { empty: true, error: this.formSubmitted ? codes.blank : null }
    }

    if (normalizedValue.length > MAX_LENGTH) {
      return { empty: false, error: codes.tooLong }
    }

    if (!CONTENT_PATTERN.test(normalizedValue)) {
      return { empty: false, error: codes.invalid }
    }

    return { empty: false, error: null }
  }

  applyState() {
    if (this.state === "LOADING") {
      this.submitButtonTarget.disabled = true
      this.submitLabelTarget.textContent = this.loadingText
      return
    }

    this.submitButtonTarget.disabled = this.state !== "READY"
    this.submitLabelTarget.textContent = this.submitDefaultText
  }

  normalized(value) {
    return this.stripTags(value).trim()
  }

  stripTags(value) {
    return String(value).replace(/<[^>]*>/g, "")
  }

  initialErrorsPresent() {
    return (
      this.skillErrorTarget.textContent.trim() !== "" ||
      this.topicErrorTarget.textContent.trim() !== ""
    )
  }
}
