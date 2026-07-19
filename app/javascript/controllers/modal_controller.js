import { Controller } from "@hotwired/stimulus"

// Opens a <dialog> whose content is loaded into a turbo frame.
export default class extends Controller {
  static targets = ["dialog"]

  open() {
    this.dialogTarget.showModal()
  }

  close() {
    this.dialogTarget.close()
  }

  // Close when clicking the backdrop (outside the dialog's content box).
  backdropClose(event) {
    if (event.target === this.dialogTarget) this.close()
  }
}
