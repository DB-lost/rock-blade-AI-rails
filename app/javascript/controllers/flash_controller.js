import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["message"]

    connect() {
        this.messageTarget.dataset.state = "showing"
        // Start the auto-dismiss timer when the flash message connects
        setTimeout(() => this.dismiss(), 5000)
    }

    dismiss() {
        // Add hiding state for animation
        this.messageTarget.dataset.state = "hiding"

        // Remove the element after animation completes
        this.messageTarget.addEventListener('transitionend', () => {
            this.messageTarget.remove()
        }, { once: true })
    }
}
