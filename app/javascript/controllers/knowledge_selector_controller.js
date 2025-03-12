import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["list", "searchInput", "counter"]

    connect() {
        // 监听显示知识库选择器事件
        window.addEventListener("show-knowledge-base-selector", this.open.bind(this))

        // 监听清除选择事件
        window.addEventListener("clear-knowledge-base-selection", this.clearSelection.bind(this))

        // 初始化选中的知识库
        this.selectedKnowledgeBases = []

        // 从localStorage恢复选择状态
        this.restoreSelectionState()
    }

    disconnect() {
        window.removeEventListener("show-knowledge-base-selector", this.open.bind(this))
        window.removeEventListener("clear-knowledge-base-selection", this.clearSelection.bind(this))
    }

    open() {
        document.getElementById("knowledge-base-selector").classList.remove("hidden")
        document.body.classList.add("overflow-hidden")

        // 恢复选择状态
        this.restoreSelectionState()
        this.updateCounter()
    }

    close() {
        document.getElementById("knowledge-base-selector").classList.add("hidden")
        document.body.classList.remove("overflow-hidden")
    }

    search() {
        const query = this.searchInputTarget.value.toLowerCase()
        const items = this.listTarget.querySelectorAll(".knowledge-base-item")

        items.forEach(item => {
            const name = item.dataset.knowledgeBaseName.toLowerCase()
            const description = item.querySelector("p")?.textContent.toLowerCase() || ""

            if (name.includes(query) || description.includes(query)) {
                item.classList.remove("hidden")
            } else {
                item.classList.add("hidden")
            }
        })
    }

    toggleSelection(event) {
        const item = event.currentTarget
        const id = item.dataset.knowledgeBaseId
        const checkbox = item.querySelector(".knowledge-base-checkbox")
        const checkIcon = checkbox.querySelector("svg")

        const index = this.selectedKnowledgeBases.indexOf(id)

        if (index === -1) {
            // 添加到选中列表
            this.selectedKnowledgeBases.push(id)
            checkbox.classList.add("bg-primary", "border-primary")
            checkIcon.classList.remove("hidden")
        } else {
            // 从选中列表移除
            this.selectedKnowledgeBases.splice(index, 1)
            checkbox.classList.remove("bg-primary", "border-primary")
            checkIcon.classList.add("hidden")
        }

        this.updateCounter()
        this.saveSelectionState()
    }

    updateCounter() {
        const count = this.selectedKnowledgeBases.length
        this.counterTarget.innerHTML = `已选择 <span class="font-medium">${count}</span> 个知识库`
    }

    confirm() {
        // 保存选择状态
        this.saveSelectionState()

        // 更新隐藏字段
        const selectedKnowledgeBasesField = document.querySelector('input[name="message[selected_knowledge_bases]"]')
        if (!selectedKnowledgeBasesField) {
            // 如果字段不存在，创建一个
            const form = document.querySelector('form')
            const input = document.createElement('input')
            input.type = 'hidden'
            input.name = 'message[selected_knowledge_bases]'
            input.value = JSON.stringify(this.selectedKnowledgeBases)
            form.appendChild(input)
        } else {
            // 更新现有字段
            selectedKnowledgeBasesField.value = JSON.stringify(this.selectedKnowledgeBases)
        }

        // 关闭选择器
        this.close()

        // 更新工具按钮状态
        const knowledgeToolButton = document.querySelector('[data-tool-type="knowledge"]')
        if (knowledgeToolButton) {
            if (this.selectedKnowledgeBases.length > 0) {
                knowledgeToolButton.classList.add("bg-primary", "text-primary-foreground")
                knowledgeToolButton.classList.remove("bg-background", "hover:bg-accent")
                knowledgeToolButton.dataset.state = "selected"
            } else {
                knowledgeToolButton.classList.remove("bg-primary", "text-primary-foreground")
                knowledgeToolButton.classList.add("bg-background", "hover:bg-accent")
                knowledgeToolButton.dataset.state = "unselected"
            }
        }
    }

    clearSelection() {
        this.selectedKnowledgeBases = []

        // 更新UI
        const checkboxes = this.element.querySelectorAll(".knowledge-base-checkbox")
        checkboxes.forEach(checkbox => {
            checkbox.classList.remove("bg-primary", "border-primary")
            checkbox.querySelector("svg").classList.add("hidden")
        })

        this.updateCounter()
        this.saveSelectionState()

        // 清除隐藏字段
        const selectedKnowledgeBasesField = document.querySelector('input[name="message[selected_knowledge_bases]"]')
        if (selectedKnowledgeBasesField) {
            selectedKnowledgeBasesField.value = "[]"
        }
    }

    saveSelectionState() {
        localStorage.setItem('selectedKnowledgeBases', JSON.stringify(this.selectedKnowledgeBases))
    }

    restoreSelectionState() {
        try {
            const saved = localStorage.getItem('selectedKnowledgeBases')
            if (saved) {
                this.selectedKnowledgeBases = JSON.parse(saved)

                // 更新UI
                this.selectedKnowledgeBases.forEach(id => {
                    const item = this.element.querySelector(`[data-knowledge-base-id="${id}"]`)
                    if (item) {
                        const checkbox = item.querySelector(".knowledge-base-checkbox")
                        checkbox.classList.add("bg-primary", "border-primary")
                        checkbox.querySelector("svg").classList.remove("hidden")
                    }
                })
            }
        } catch (e) {
            console.error("Error restoring knowledge base selection state", e)
            this.selectedKnowledgeBases = []
        }
    }
}