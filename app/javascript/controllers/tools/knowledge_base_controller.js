import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["checkbox"]

    connect() {
        this.kbId = this.element.dataset.kbId
        this.initializeState()
    }

    initializeState() {
        // 检查初始选中状态
        setTimeout(() => {
            const selectedKnowledgeBases = JSON.parse(document.querySelector('[name="message[selected_knowledge_bases]"]').value || '[]')
            if (selectedKnowledgeBases.includes(this.kbId)) {
                // 找到复选框按钮并设置选中状态
                const checkboxElement = this.element.querySelector('[role="checkbox"]')
                if (checkboxElement) {
                    const checkmark = checkboxElement.querySelector("span")
                    checkmark.classList.remove("hidden")
                    checkboxElement.dataset.state = "checked"
                }
            }
        }, 100)
    }

    toggleKnowledgeBase(event) {
        console.log('toggleKnowledgeBase:', "我执行了", event.detail)
        // 获取复选框的选中状态
        const isChecked = event.detail.checked
        const selectedKnowledgeBases = JSON.parse(document.querySelector('[name="message[selected_knowledge_bases]"]').value || '[]')

        if (isChecked) {
            if (!selectedKnowledgeBases.includes(this.kbId)) {
                selectedKnowledgeBases.push(this.kbId)
            }
        } else {
            const index = selectedKnowledgeBases.indexOf(this.kbId)
            if (index !== -1) {
                selectedKnowledgeBases.splice(index, 1)
            }
        }

        // 更新隐藏字段
        document.querySelector('[name="message[selected_knowledge_bases]"]').value = JSON.stringify(selectedKnowledgeBases)

        // 通知状态变化
        this.notifySelectionChange(selectedKnowledgeBases.length)
    }

    notifySelectionChange(selectedCount) {
        const event = new CustomEvent('knowledgeBasesChanged', {
            detail: { selectedCount },
            bubbles: true
        })
        document.dispatchEvent(event)
    }
}
