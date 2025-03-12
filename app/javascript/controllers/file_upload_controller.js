import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dropzone", "input", "form", "preview", "filename"]

    connect() {
        this.setupDropzone()
    }

    setupDropzone() {
        const dropzone = this.dropzoneTarget

            // 阻止默认拖放行为
            ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
                dropzone.addEventListener(eventName, this.preventDefaults, false)
            })

            // 高亮显示拖放区域
            ;['dragenter', 'dragover'].forEach(eventName => {
                dropzone.addEventListener(eventName, () => {
                    dropzone.classList.add('border-primary')
                }, false)
            })

            ;['dragleave', 'drop'].forEach(eventName => {
                dropzone.addEventListener(eventName, () => {
                    dropzone.classList.remove('border-primary')
                }, false)
            })

        // 处理文件拖放
        dropzone.addEventListener('drop', this.handleDrop.bind(this), false)
    }

    preventDefaults(e) {
        e.preventDefault()
        e.stopPropagation()
    }

    handleDrop(e) {
        const dt = e.dataTransfer
        const files = dt.files

        if (files.length > 0) {
            this.inputTarget.files = files
            this.handleFileSelect()
        }
    }

    triggerFileInput() {
        this.inputTarget.click()
    }

    handleFileSelect() {
        const file = this.inputTarget.files[0]

        if (file) {
            // 显示文件预览
            this.dropzoneTarget.classList.add('hidden')
            this.previewTarget.classList.remove('hidden')
            this.filenameTarget.textContent = file.name
        }
    }

    clearFile() {
        this.inputTarget.value = ''
        this.dropzoneTarget.classList.remove('hidden')
        this.previewTarget.classList.add('hidden')
    }

    uploadFile() {
        this.formTarget.submit()
    }
} 