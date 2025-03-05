import { Controller } from "@hotwired/stimulus"

// 控制文本区域向上拉伸的控制器
export default class extends Controller {
    connect() {
        this.element.addEventListener('mousedown', this.startResize.bind(this))
    }

    disconnect() {
        this.element.removeEventListener('mousedown', this.startResize.bind(this))
        document.removeEventListener('mousemove', this.resize)
        document.removeEventListener('mouseup', this.stopResize)
    }

    startResize(event) {
        // 防止默认行为
        event.preventDefault()

        // 获取文本区域和父容器
        const container = this.element.closest('.resize-upward')
        const textarea = container.querySelector('textarea')

        // 保存初始高度和鼠标位置
        this.initialHeight = textarea.offsetHeight
        this.initialY = event.clientY

        // 设置鼠标移动和释放事件
        this.resize = this.handleResize.bind(this, textarea, container)
        this.stopResize = this.handleStopResize.bind(this)

        document.addEventListener('mousemove', this.resize)
        document.addEventListener('mouseup', this.stopResize)
    }

    handleResize(textarea, container, event) {
        // 计算鼠标移动的差值（向上为正，向下为负）
        const delta = this.initialY - event.clientY

        // 设置新高度（初始高度加上位移，向上拉伸增加高度）
        const minHeight = 50; // 提高最小高度到50px
        const newHeight = Math.max(minHeight, this.initialHeight + delta)
        textarea.style.height = `${newHeight}px`
        container.style.height = `${newHeight}px`
    }

    handleStopResize() {
        document.removeEventListener('mousemove', this.resize)
        document.removeEventListener('mouseup', this.stopResize)
    }
} 