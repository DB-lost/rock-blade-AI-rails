import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "selectedTools", "knowledgeList"]

    connect() {
        this.selectedToolTypes = []
        this.buttonTargets.forEach(button => {
            this.resetButtonState(button)
        })

        // 监听知识库选择变化 - 同时在元素和document级别监听事件
        this.element.addEventListener('knowledgeBasesChanged', this.handleKnowledgeBasesChanged.bind(this))
        document.addEventListener('knowledgeBasesChanged', this.handleKnowledgeBasesChanged.bind(this))

        // 添加点击外部关闭列表的处理
        document.addEventListener('click', this.handleClickOutside.bind(this))
    }

    disconnect() {
        document.removeEventListener('click', this.handleClickOutside.bind(this))
        document.removeEventListener('knowledgeBasesChanged', this.handleKnowledgeBasesChanged.bind(this))
    }

    handleClickOutside(event) {
        if (this.hasKnowledgeListTarget) {
            const knowledgeButton = this.buttonTargets.find(button => button.dataset.toolType === "knowledge")
            const isClickInside = event.target.closest('[data-tools-target="knowledgeList"]') ||
                event.target === knowledgeButton ||
                knowledgeButton.contains(event.target)

            if (!isClickInside) {
                this.knowledgeListTarget.classList.add('hidden')
            }
        }
    }

    toggle(event) {
        const button = event.currentTarget
        const toolType = button.dataset.toolType
        const currentState = button.dataset.state

        if (toolType === "knowledge") {
            // 对于知识库按钮，只控制列表显示/隐藏
            if (this.hasKnowledgeListTarget) {
                this.knowledgeListTarget.classList.toggle("hidden")
            }
        } else {
            // 其他按钮正常处理选中状态
            if (currentState === "unselected") {
                this.setButtonSelected(button)
                this.selectedToolTypes.push(toolType)
            } else {
                this.resetButtonState(button)
                const index = this.selectedToolTypes.indexOf(toolType)
                if (index !== -1) {
                    this.selectedToolTypes.splice(index, 1)
                }
            }
        }

        // 使用 Rails 的数组参数命名约定
        if (this.hasSelectedToolsTarget) {
            // 清空现有的隐藏字段
            this.selectedToolsTarget.value = ""

            // 如果有选中的工具，则设置为 JSON 字符串
            if (this.selectedToolTypes.length > 0) {
                this.selectedToolsTarget.value = JSON.stringify(this.selectedToolTypes)
            }
        }
    }

    setButtonSelected(button) {
        button.dataset.state = "selected"
        button.setAttribute("variant", "default")
        button.classList.add("bg-primary", "text-primary-foreground", "hover:bg-primary/90")
        button.classList.remove("bg-background", "hover:bg-accent")
    }

    resetButtonState(button) {
        button.dataset.state = "unselected"
        button.setAttribute("variant", "outline")
        button.classList.remove("bg-primary", "text-primary-foreground", "hover:bg-primary/90")
        button.classList.add("bg-background", "hover:bg-accent")
    }

    handleKnowledgeBasesChanged(event) {
        const knowledgeButton = this.buttonTargets.find(button => button.dataset.toolType === "knowledge")
        if (knowledgeButton) {
            if (event.detail.selectedCount > 0) {
                this.setButtonSelected(knowledgeButton)
                if (!this.selectedToolTypes.includes("knowledge")) {
                    this.selectedToolTypes.push("knowledge")
                }
            } else {
                this.resetButtonState(knowledgeButton)
                const index = this.selectedToolTypes.indexOf("knowledge")
                if (index !== -1) {
                    this.selectedToolTypes.splice(index, 1)
                }
            }

            // 更新隐藏字段
            if (this.hasSelectedToolsTarget) {
                this.selectedToolsTarget.value = this.selectedToolTypes.length > 0 ? JSON.stringify(this.selectedToolTypes) : ""
            }
        }
    }
}
