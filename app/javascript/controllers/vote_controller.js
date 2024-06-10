// app/javascript/controllers/vote_controller.js
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["count"];

  vote(event) {
    event.preventDefault();
    const url = event.currentTarget.href;

    fetch(url, {
      method: 'POST',
      headers: {
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
        'Accept': 'application/json'
      }
    })
    .then(response => response.json())
    .then(data => {
      if (data.success) {
        this.countTarget.textContent = data.votes_count;
      } else {
        alert(data.error);
      }
    })
    .catch(error => {
      console.error(error);
    });
  }
}
