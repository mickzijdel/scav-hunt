import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  togglePermission(event) {
    const checkbox = event.target
    const userId = checkbox.dataset.userId
    const groupId = checkbox.dataset.groupId
    const permitted = checkbox.checked

    fetch('/group_permissions/update', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ user_id: userId, group_id: groupId, permitted: permitted })
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // FIXME: Show some visual feedback.
      } else {
        // FIXME: Show some error feedback.
        checkbox.checked = !permitted
        console.error('Error updating group permission:', data.errors)
      }
    })
    .catch(error => {
      // FIXME: Show some error feedback.
      checkbox.checked = !permitted
      console.error('Error:', error)
  })
  }
}