import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["button", "selectedTools"]

    connect() {
        this.selectedToolTypes = []
        this.buttonTargets.forEach(button => {
            this.resetButtonState(button)
        })
    }

    toggle(event) {
        const button = event.currentTarget
        const toolType = button.dataset.toolType
        const currentState = button.dataset.state

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
}
