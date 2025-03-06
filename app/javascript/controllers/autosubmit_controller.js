import { Controller } from "@hotwired/stimulus"

// 处理表单自动提交和按钮禁用的控制器
export default class extends Controller {
    static targets = ["input", "submit"]

    connect() {
        this.inputTarget.addEventListener("keydown", this.handleKeyDown.bind(this))
    }

    disconnect() {
        this.inputTarget.removeEventListener("keydown", this.handleKeyDown)
    }

    handleKeyDown(event) {
        // 如果按下 Ctrl+Enter 或 Command+Enter
        if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
            event.preventDefault()
            this.submit()
        }
    }

    submit() {
        if (this.inputTarget.value.trim() === "") return

        // 禁用输入和按钮
        this.inputTarget.disabled = true
        this.submitTarget.disabled = true

        // 提交表单
        this.element.requestSubmit()

        // 清空输入框
        setTimeout(() => {
            this.inputTarget.value = ""
            this.inputTarget.disabled = false
            this.submitTarget.disabled = false
            this.inputTarget.focus()
        }, 100)
    }
} 