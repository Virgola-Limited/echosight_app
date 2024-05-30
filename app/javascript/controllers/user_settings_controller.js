// app/javascript/controllers/user_settings_controller.js
import { Controller } from "@hotwired/stimulus"
import Rails from "@rails/ujs"

export default class extends Controller {
  static targets = [ "toggle" ]

  connect() {
    console.log('test3')
  }

  updateSetting(event) {
    const key = event.target.name.split("[")[1].split("]")[0]
    const value = event.target.checked ? 'true' : 'false'

    Rails.ajax({
      url: "/user_settings",
      type: "PUT",
      data: `user_settings[${key}]=${value}`,
      success: (data) => {
        console.log("Setting updated successfully")
      },
      error: (data) => {
        console.error("Failed to update setting")
      }
    })
  }
}
