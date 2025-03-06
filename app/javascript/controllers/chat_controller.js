import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "input"]

    connect() {
        this.scrollToBottom()

        // 监听Turbo Stream事件，每当新消息添加时滚动到底部
        document.addEventListener("turbo:before-stream-render", (event) => {
            const turboStream = event.detail?.newStream

            if (turboStream?.action === "append") {
                // 等渲染完成后滚动
                setTimeout(() => this.scrollToBottom(), 50)
            }
        })

        // 初始化时调整高度
        if (this.hasInputTarget) {
            this.adjustHeight({ target: this.inputTarget })
        }
    }

    scrollToBottom() {
        const container = this.containerTarget
        container.scrollTop = container.scrollHeight
    }

    checkSubmit(event) {
        // 按Enter发送，按Shift+Enter换行
        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault()

            // 获取并检查内容
            const content = this.inputTarget.value.trim()
            if (!content) return

            // 立即清空输入框并重置高度
            this.inputTarget.value = ""
            this.inputTarget.style.height = "auto"

            // 提交表单
            event.target.form.requestSubmit()
        }
    }

    // 自动调整文本区域高度
    adjustHeight(event) {
        const textarea = event.target

        // 重置高度以获取正确的scrollHeight
        textarea.style.height = "auto"

        // 设置新高度 (增加最小高度)
        const minHeight = 50; // 提高最小高度到50px
        const newHeight = Math.max(textarea.scrollHeight, minHeight)
        textarea.style.height = `${newHeight}px`

        // 如果使用了向上拉升样式，需要调整父容器
        const upwardContainer = textarea.closest('.resize-upward')
        if (upwardContainer) {
            upwardContainer.style.height = `${newHeight}px`
        }
    }
}
