import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["container", "input"]

    connect() {
        this.scrollToBottom()

        // 监听 Turbo Stream 事件
        document.addEventListener("turbo:before-stream-render", (event) => {
            const turboStream = event.detail?.newStream

            // 处理新消息添加、替换和更新
            if (turboStream?.action === "append" ||
                turboStream?.action === "replace" ||
                turboStream?.action === "update") {
                // 更高效的滚动处理
                this.scrollToBottomDebounced()
            }
        })

        // 初始化防抖函数
        this.scrollToBottomDebounced = this.debounce(this.scrollToBottom.bind(this), 50)

        // 初始化时调整高度
        if (this.hasInputTarget) {
            // 首先确保高度是自动的
            this.inputTarget.style.height = "auto"
            const upwardContainer = this.inputTarget.closest('.resize-upward')
            if (upwardContainer) {
                upwardContainer.style.height = "auto"
            }

            // 然后执行调整
            this.adjustHeight({ target: this.inputTarget })
        }

        // 添加 MutationObserver 来监听消息容器的变化
        this.setupMutationObserver()
    }

    disconnect() {
        // 断开连接时关闭 MutationObserver
        if (this.observer) {
            this.observer.disconnect()
        }
    }

    // 设置 MutationObserver 来监听消息容器的变化
    setupMutationObserver() {
        const messagesContainer = document.getElementById('conversation_messages')
        if (!messagesContainer) return

        this.observer = new MutationObserver((mutations) => {
            let shouldScroll = false

            mutations.forEach(mutation => {
                if (mutation.type === 'childList' && mutation.addedNodes.length > 0) {
                    shouldScroll = true
                }
            })

            if (shouldScroll) {
                this.scrollToBottomDebounced()
            }
        })

        this.observer.observe(messagesContainer, {
            childList: true,
            subtree: true
        })
    }

    // 防抖函数
    debounce(func, wait) {
        let timeout
        return function executedFunction(...args) {
            const later = () => {
                clearTimeout(timeout)
                func(...args)
            }
            clearTimeout(timeout)
            timeout = setTimeout(later, wait)
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

            // 提交表单
            event.target.form.requestSubmit()
            // 立即清空输入框并重置高度
            this.inputTarget.value = ""
            this.inputTarget.style.height = "auto"

            // 同时重置resize-upward容器的高度
            const upwardContainer = this.inputTarget.closest('.resize-upward')
            if (upwardContainer) {
                upwardContainer.style.height = "auto"
            }

            // 禁用输入框，防止重复提交
            this.inputTarget.disabled = true

            // 1秒后重新启用输入框
            setTimeout(() => {
                this.inputTarget.disabled = false
                this.inputTarget.focus()
            }, 1000)
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
