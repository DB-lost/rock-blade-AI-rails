import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["switch", "price", "billingText", "switchTrack", "switchThumb"]

    connect() {
        // Initialize price display on connection
        this.updatePricing(false)
    }

    togglePricing(event) {
        const isYearly = event.target.checked
        this.updatePricing(isYearly)
        this.animateSwitch(isYearly)
    }

    updatePricing(isYearly) {
        this.priceTargets.forEach(element => {
            // Add fade out animation
            element.classList.add('opacity-0')
            setTimeout(() => {
                element.textContent = isYearly ? element.dataset.yearly : element.dataset.monthly
                // Add fade in animation
                element.classList.remove('opacity-0')
            }, 150)
        })

        this.billingTextTargets.forEach(element => {
            // Add fade out animation
            element.classList.add('opacity-0')
            setTimeout(() => {
                element.textContent = isYearly ? element.dataset.yearly : element.dataset.monthly
                // Add fade in animation
                element.classList.remove('opacity-0')
            }, 150)
        })
    }

    animateSwitch(isYearly) {
        // Animate the switch track
        if (isYearly) {
            this.switchTrackTarget.classList.add('bg-primary')
            this.switchTrackTarget.classList.remove('bg-gray-200')
        } else {
            this.switchTrackTarget.classList.remove('bg-primary')
            this.switchTrackTarget.classList.add('bg-gray-200')
        }

        // Animate the switch thumb
        if (isYearly) {
            this.switchThumbTarget.classList.add('translate-x-full')
        } else {
            this.switchThumbTarget.classList.remove('translate-x-full')
        }
    }
}
