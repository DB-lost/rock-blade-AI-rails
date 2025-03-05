import { Controller } from "@hotwired/stimulus"

// 控制助手列表和右键菜单功能
export default class extends Controller {
    static targets = ["menu"]

    connect() {
        // 点击页面其他地方关闭菜单
        document.addEventListener('click', (e) => {
            if (!this.element.contains(e.target)) {
                this.hideMenu();
            }
        });
    }

    selectAssistant(event) {
        // 左键点击选中助手
        const assistantId = this.element.dataset.assistantMenuIdValue;
        window.location.href = `/assistants/${assistantId}`;
    }

    showMenu(event) {
        // 阻止默认右键菜单
        event.preventDefault();

        // 隐藏所有其他菜单
        document.querySelectorAll('[data-assistant-menu-target="menu"]').forEach(menu => {
            menu.classList.add('hidden');
        });

        // 显示当前菜单
        this.menuTarget.classList.remove('hidden');
    }

    hideMenu() {
        if (this.hasMenuTarget) {
            this.menuTarget.classList.add('hidden');
        }
    }

    // 菜单操作方法
    editAssistant(event) {
        const assistantId = this.element.dataset.assistantMenuIdValue;
        window.location.href = `/assistants/${assistantId}/edit`;
    }

    copyAssistant(event) {
        const assistantId = this.element.dataset.assistantMenuIdValue;
        // 发送复制助手请求
        fetch(`/assistants/${assistantId}/duplicate`, {
            method: 'POST',
            headers: {
                'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                'Content-Type': 'application/json'
            }
        })
            .then(response => {
                if (response.ok) {
                    window.location.reload();
                }
            });
    }

    clearTopics(event) {
        const assistantId = this.element.dataset.assistantMenuIdValue;
        if (confirm('确定要清空所有话题吗？')) {
            fetch(`/assistants/${assistantId}/clear_topics`, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                    'Content-Type': 'application/json'
                }
            })
                .then(response => {
                    if (response.ok) {
                        window.location.reload();
                    }
                });
        }
    }

    saveToAgent(event) {
        const assistantId = this.element.dataset.assistantMenuIdValue;
        // 实现保存到智能体的逻辑
        alert('将助手保存为独立智能体的功能正在开发中');
    }

    deleteAssistant(event) {
        const assistantId = this.element.dataset.assistantMenuIdValue;
        if (confirm('确定要删除这个助手吗？')) {
            fetch(`/assistants/${assistantId}`, {
                method: 'DELETE',
                headers: {
                    'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content,
                    'Content-Type': 'application/json'
                }
            })
                .then(response => {
                    if (response.ok) {
                        window.location.reload();
                    }
                });
        }
    }
} 