import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  togglePermission(event) {
    const checkbox = event.target

    const userId = checkbox.dataset.userid
    const groupId = checkbox.dataset.groupid
    const permitted = checkbox.checked
    const data = { user_id: userId, group_id: groupId, permitted: permitted }

    fetch('/group_permissions', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        // csrf_meta_tags renders nothing when forgery protection is disabled
        // (as it is in the test environment), so this tag is not always present.
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.content ?? ''
      },
      body: JSON.stringify(data)
    })
    .then(response => response.json())
    .then(data => {
      if (data.status === 'success') {
        // FIXME: Show some visual feedback.
      } else {
        // FIXME: Show some error feedback.
        checkbox.checked = !permitted
        console.error('GroupPermissionsController: Error updating group permission:', data.errors)
      }
    })
    .catch(error => {
      // FIXME: Show some error feedback.
      checkbox.checked = !permitted
      console.error('GroupPermissionsController: Error:', error)
  })
  }
}