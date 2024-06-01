// app/javascript/controllers/debounce_controller.js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["button"]

  connect() {
    this.timeout = null
  }

  handleClick(event) {
    console.log('Button clicked')
    if (this.timeout) {
      event.preventDefault()
      return
    }

    this.timeout = setTimeout(() => {
      this.timeout = null
    }, 3000)
  }
}
