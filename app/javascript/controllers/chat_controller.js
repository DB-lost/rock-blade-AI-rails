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
    }

    scrollToBottom() {
        const container = this.containerTarget
        container.scrollTop = container.scrollHeight
    }

    checkSubmit(event) {
        // 按Enter发送，按Shift+Enter换行
        if (event.key === "Enter" && !event.shiftKey) {
            event.preventDefault()
            event.target.form.requestSubmit()
        }
    }
} 