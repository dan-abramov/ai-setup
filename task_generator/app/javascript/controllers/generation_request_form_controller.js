import { Controller } from "@hotwired/stimulus"

const MAX_LENGTH = 100
const RETRYABLE_ERROR_CODES = new Set(["E204", "E205", "E206", "E207", "E208", "E209", "E301"])

export default class extends Controller {
  static targets = [
    "form",
    "skillInput",
    "topicInput",
    "submitButton",
    "stateLabel",
    "errorMessage",
    "retryButton"
  ]

  static values = {
    stateLabels: Object,
    errorMessages: Object,
    loadingText: String
  }

  connect() {
    this.defaultSubmitText = this.submitButtonTarget.textContent.trim()
    this.state = "EMPTY"
    this.lastErrorCode = null
    this.submittedOnce = false
    this.setState("EMPTY")
    this.hide(this.errorMessageTarget)
    this.hide(this.retryButtonTarget)
  }

  onInput() {
    if (this.state === "LOADING" || !this.submittedOnce) {
      return
    }

    const inputErrorCode = this.inputErrorCode()

    if (inputErrorCode) {
      this.renderError(inputErrorCode)
      return
    }

    if (!this.retryableError(this.lastErrorCode)) {
      this.resetToEmpty()
    }
  }

  async submit(event) {
    event.preventDefault()

    if (this.state === "LOADING") {
      return
    }

    this.submittedOnce = true

    const inputErrorCode = this.inputErrorCode()
    if (inputErrorCode) {
      this.renderError(inputErrorCode)
      return
    }

    await this.performSubmit()
  }

  async retry(event) {
    event.preventDefault()

    if (this.state === "LOADING" || !this.retryableError(this.lastErrorCode)) {
      return
    }

    await this.performSubmit()
  }

  async performSubmit() {
    this.setState("LOADING")
    this.hide(this.errorMessageTarget)
    this.hide(this.retryButtonTarget)

    try {
      const response = await fetch(this.formTarget.action, {
        method: "POST",
        headers: {
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken(),
          "X-Requested-With": "XMLHttpRequest"
        },
        body: new FormData(this.formTarget),
        credentials: "same-origin"
      })

      const payload = await this.parseJson(response)

      if (response.ok && payload.state === "SUCCESS") {
        this.renderSuccess(payload)
        return
      }

      this.renderError(payload.error_code || "E205")
    } catch (_error) {
      this.renderError("E205")
    }
  }

  renderSuccess(payload) {
    const taskId = payload.task_id
    const taskPath = String(payload.task_path || "").trim()

    if (!taskId || taskPath === "") {
      this.renderError("E205")
      return
    }

    this.lastErrorCode = null
    this.setState("SUCCESS")
    this.hide(this.errorMessageTarget)
    this.hide(this.retryButtonTarget)
    window.location.assign(taskPath)
  }

  renderError(errorCode) {
    this.lastErrorCode = errorCode
    this.setState("ERROR")

    const message = this.errorMessagesValue[errorCode] || this.errorMessagesValue.E205 || "Ошибка генерации"
    this.errorMessageTarget.textContent = `${message} (${errorCode})`

    this.show(this.errorMessageTarget)

    if (this.retryableError(errorCode)) {
      this.show(this.retryButtonTarget)
    } else {
      this.hide(this.retryButtonTarget)
    }
  }

  resetToEmpty() {
    this.lastErrorCode = null
    this.setState("EMPTY")
    this.hide(this.errorMessageTarget)
    this.hide(this.retryButtonTarget)
  }

  setState(nextState) {
    this.state = nextState
    this.stateLabelTarget.textContent = this.stateLabelsValue[nextState] || nextState

    if (nextState === "LOADING") {
      this.submitButtonTarget.disabled = true
      this.submitButtonTarget.textContent = this.loadingTextValue || this.defaultSubmitText
      return
    }

    this.submitButtonTarget.disabled = false
    this.submitButtonTarget.textContent = this.defaultSubmitText
  }

  inputErrorCode() {
    const skill = this.normalized(this.skillInputTarget.value)
    const topic = this.normalized(this.topicInputTarget.value)

    if (skill === "") {
      return "E201"
    }

    if (topic === "") {
      return "E202"
    }

    if (skill.length > MAX_LENGTH || topic.length > MAX_LENGTH) {
      return "E203"
    }

    return null
  }

  retryableError(errorCode) {
    return RETRYABLE_ERROR_CODES.has(errorCode)
  }

  normalized(value) {
    return this.stripTags(String(value)).trim()
  }

  stripTags(value) {
    return value.replace(/<[^>]*>/g, "")
  }

  parseJson(response) {
    return response
      .text()
      .then((body) => {
        if (body === "") {
          return {}
        }

        try {
          return JSON.parse(body)
        } catch (_error) {
          return {}
        }
      })
  }

  csrfToken() {
    const tokenTag = document.querySelector("meta[name='csrf-token']")
    return tokenTag ? tokenTag.content : ""
  }

  show(element) {
    element.classList.remove("hidden")
  }

  hide(element) {
    element.classList.add("hidden")
  }
}
