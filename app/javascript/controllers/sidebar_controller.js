import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["panel", "spacer", "collapsible"]

    connect() {
        // 从 localStorage 获取侧边栏状态
        const isExpanded = localStorage.getItem("sidebarExpanded") !== "false"
        this.toggleSidebar(isExpanded)
    }

    toggle() {
        const isExpanded = this.panelTarget.classList.contains("w-64")
        this.toggleSidebar(!isExpanded)
        localStorage.setItem("sidebarExpanded", !isExpanded)
    }

    toggleSidebar(isExpanded) {
        // 处理面板和占位符的宽度
        [this.panelTarget, this.spacerTarget].forEach(element => {
            if (isExpanded) {
                element.classList.remove("w-16")
                element.classList.add("w-64")
            } else {
                element.classList.remove("w-64")
                element.classList.add("w-16")
            }
        })

        // 处理所有可折叠元素的显示/隐藏
        this.collapsibleTargets.forEach(element => {
            if (isExpanded) {
                element.classList.remove("opacity-0")
                if (element.classList.contains("text-sm")) {
                    element.classList.remove("hidden")
                }
            } else {
                element.classList.add("opacity-0")
                if (element.classList.contains("text-sm")) {
                    element.classList.add("hidden")
                }
            }
        })
    }
} 