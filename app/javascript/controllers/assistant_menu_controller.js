import { Controller } from "@hotwired/stimulus"

// 控制助手列表和右键菜单功能
export default class extends Controller {
    static targets = ["menu"]
    static values = {
        id: String,
        active: Boolean
    }

    connect() {
        // 点击页面其他地方关闭菜单
        document.addEventListener('click', (e) => {
            if (!this.element.contains(e.target)) {
                this.hideMenu();
            }
        });

        // 初始化时检查是否是上次使用的assistant
        const lastUsedId = document.querySelector('meta[name="last-used-assistant-id"]')?.content;
        if (lastUsedId === this.idValue) {
            this.setActive(true);
        }
    }

    selectAssistant(event) {
        // 清除其他助手的选中状态
        document.querySelectorAll('[data-controller="assistant-menu"]').forEach(element => {
            if (element !== this.element) {
                const controller = this.application.getControllerForElementAndIdentifier(element, 'assistant-menu');
                controller.setActive(false);
            }
        });

        // 设置当前助手为选中状态
        this.setActive(true);

        // 记录最后使用的assistant
        const assistantId = this.idValue;
        fetch(`/assistants/${assistantId}/set_last_used`, {
            method: 'POST',
            headers: {
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                'Content-Type': 'application/json'
            }
        }).then(response => {
            if (response.ok) {
                // 加载该assistant的对话内容
                Turbo.visit(`/ai_chats?assistant_id=${assistantId}`, { action: 'replace' });
            }
        });
    }

    setActive(active) {
        this.activeValue = active;
        if (active) {
            this.element.classList.add('bg-muted');
            this.element.classList.remove('border-transparent');
            this.element.classList.add('border-primary');
        } else {
            this.element.classList.remove('bg-muted');
            this.element.classList.add('border-transparent');
            this.element.classList.remove('border-primary');
        }
    }

    showMenu(event) {
        // 阻止默认右键菜单和点击事件冒泡
        event.preventDefault();
        event.stopPropagation();

        // 隐藏所有其他菜单
        document.querySelectorAll('[data-assistant-menu-target="menu"]').forEach(menu => {
            menu.classList.add('hidden');
        });

        // 显示当前菜单
        this.menuTarget.classList.remove('hidden');
    }

    // 防止菜单点击事件冒泡到assistant元素
    preventBubble(event) {
        event.stopPropagation();
    }

    hideMenu() {
        if (this.hasMenuTarget) {
            this.menuTarget.classList.add('hidden');
        }
    }

}
