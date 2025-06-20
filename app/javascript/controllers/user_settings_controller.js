import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "toggle" ]

  updateSetting(event) {
    const key = event.target.name.split("[")[1].split("]")[0]
    const value = event.target.checked ? 'true' : 'false'
    const csrfTokenMeta = document.querySelector('meta[name="csrf-token"]');
    const csrfToken = csrfTokenMeta ? csrfTokenMeta.getAttribute('content') : null;

    fetch("/user_settings", {
      method: "PUT",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        ...(csrfToken && { "X-CSRF-Token": csrfToken })
      },
      body: `user_settings[${key}]=${value}`
    })
    .then(response => {
      if (!response.ok) {
        throw new Error("Network response was not ok");
      }
      return response.json();
    })
    .then(data => {
      this.showFlashMessage('Setting updated successfully', 'notice')
    })
    .catch(error => {
      this.showFlashMessage('Failed to update setting', 'alert')
    });
  }

  // TODO: Extract this to shared code
  showFlashMessage(message, type) {
    let flashMessageDiv = document.querySelector(`#flash-messages .${type}`)

    if (!flashMessageDiv) {
      flashMessageDiv = document.createElement('div')
      flashMessageDiv.className = `p-4 mb-4 text-sm rounded-lg ${type === 'notice' ? 'text-green-800 bg-green-50 dark:bg-gray-800 dark:text-green-400' : 'text-red-800 bg-red-50 dark:bg-gray-800 dark:text-red-400'}`
      flashMessageDiv.setAttribute('role', 'alert')
      flashMessageDiv.classList.add(type)
      document.querySelector("#flash-messages").appendChild(flashMessageDiv)
    }

    flashMessageDiv.innerText = message

    setTimeout(() => {
      flashMessageDiv.remove()
    }, 3000)
  }
}
