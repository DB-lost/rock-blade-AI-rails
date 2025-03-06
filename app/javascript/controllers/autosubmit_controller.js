import { Controller } from "@hotwired/stimulus"

// 处理表单自动提交和按钮禁用的控制器
export default class extends Controller {
    static targets = ["input", "submit"]

    connect() {
        this.inputTarget.addEventListener("keydown", this.handleKeyDown.bind(this))
        // 添加对自定义chat:submit事件的监听
        this.inputTarget.addEventListener("chat:submit", this.submit.bind(this))
    }

    disconnect() {
        this.inputTarget.removeEventListener("keydown", this.handleKeyDown)
        this.inputTarget.removeEventListener("chat:submit", this.submit)
    }

    handleKeyDown(event) {
        // 如果按下 Ctrl+Enter 或 Command+Enter
        if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
            event.preventDefault()
            this.submit()
        }
    }

    submit(event) {
        if (event) event.preventDefault()

        // 获取并检查内容
        const content = this.inputTarget.value.trim()
        if (content === "") return

        // 禁用输入和按钮以防止重复提交
        this.inputTarget.disabled = true
        this.submitTarget.disabled = true

        try {
            // 创建一个隐藏字段来保存当前内容值
            const hiddenInput = document.createElement('input')
            hiddenInput.type = 'hidden'
            hiddenInput.name = this.inputTarget.name
            hiddenInput.value = content
            this.element.appendChild(hiddenInput)

            // 提交表单
            this.element.requestSubmit()

            // 在表单提交后清空输入框
            setTimeout(() => {
                // 清空输入框
                this.inputTarget.value = ""

                // 重置textarea高度
                this.inputTarget.style.height = "auto"
                const upwardContainer = this.inputTarget.closest('.resize-upward')
                if (upwardContainer) {
                    upwardContainer.style.height = "auto"
                }

                // 重新启用输入框
                this.inputTarget.disabled = false
                this.submitTarget.disabled = false
                this.inputTarget.focus()

                // 删除临时隐藏字段
                this.element.removeChild(hiddenInput)
            }, 200) // 稍微延长一点时间确保表单已经提交
        } catch (error) {
            console.error("表单提交错误:", error)
            // 重新启用输入框
            this.inputTarget.disabled = false
            this.submitTarget.disabled = false
        }
    }
} 