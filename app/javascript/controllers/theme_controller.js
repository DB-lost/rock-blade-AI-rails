import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["darkIcon", "lightIcon"]

    connect() {
        this.updateTheme()
    }

    updateTheme() {
        const darkIcon = this.darkIconTarget
        const lightIcon = this.lightIconTarget

        if (localStorage.theme === 'dark' || (!('theme' in localStorage) && window.matchMedia('(prefers-color-scheme: dark)').matches)) {
            document.documentElement.classList.add('dark')
            darkIcon.classList.add('hidden')
            lightIcon.classList.remove('hidden')
        } else {
            document.documentElement.classList.remove('dark')
            lightIcon.classList.add('hidden')
            darkIcon.classList.remove('hidden')
        }
    }

    toggle() {
        const darkIcon = this.darkIconTarget
        const lightIcon = this.lightIconTarget

        if (document.documentElement.classList.contains('dark')) {
            document.documentElement.classList.remove('dark')
            localStorage.theme = 'light'
            lightIcon.classList.add('hidden')
            darkIcon.classList.remove('hidden')
        } else {
            document.documentElement.classList.add('dark')
            localStorage.theme = 'dark'
            darkIcon.classList.add('hidden')
            lightIcon.classList.remove('hidden')
        }
    }
} 