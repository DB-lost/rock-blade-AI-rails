import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["tab", "content", "footer"]

    connect() {
        // 初始化时确保第一个标签页处于激活状态
        this.switchToTab("assistants")
    }

    switchTab(event) {
        const tabId = event.currentTarget.dataset.tabId
        this.switchToTab(tabId)
    }

    switchToTab(tabId) {
        // 更新标签按钮样式
        this.tabTargets.forEach(tab => {
            if (tab.dataset.tabId === tabId) {
                tab.classList.add("border-primary")
                tab.classList.remove("border-transparent", "text-muted-foreground")
            } else {
                tab.classList.remove("border-primary")
                tab.classList.add("border-transparent", "text-muted-foreground")
            }
        })

        // 显示/隐藏内容区域
        this.contentTargets.forEach(content => {
            if (content.dataset.contentId === tabId) {
                content.classList.remove("hidden")
            } else {
                content.classList.add("hidden")
            }
        })

        // 显示/隐藏底部按钮区域
        this.footerTargets.forEach(footer => {
            if (footer.dataset.footerId === tabId) {
                footer.classList.remove("hidden")
            } else {
                footer.classList.add("hidden")
            }
        })
    }
} 