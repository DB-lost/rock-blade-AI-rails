import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["phone", "sendButton"]

  connect() {
    // 恢复上次使用的手机号码
    const lastUsedPhone = localStorage.getItem('lastUsedPhone')
    if (lastUsedPhone) {
      this.phoneTarget.value = lastUsedPhone
      this.checkLastSendTime(lastUsedPhone)
    }
  }

  async sendCode(event) {
    event.preventDefault()

    const phone = this.phoneTarget.value
    if (!phone) {
      alert('Please enter your phone number')
      return
    }
    if (!this.canSend(phone)) return

    try {
      const response = await fetch('/registration/send_verification_code', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('[name="csrf-token"]').content
        },
        body: JSON.stringify({ phone })
      })

      const data = await response.json()
      if (response.ok && data.status === "success") {
        // 只在真正发送成功时才保存时间和开始倒计时
        const now = Date.now()
        localStorage.setItem(`lastSendTime_${phone}`, now)
        localStorage.setItem('lastUsedPhone', phone)
        this.startCountdown(now)
      } else {
        // 显示错误信息，不影响重试
        alert(data.message || 'Send failure')
      }
    } catch (error) {
      alert('Network error')
    }
  }

  canSend(phone) {
    const lastSendTime = localStorage.getItem(`lastSendTime_${phone}`)
    if (!lastSendTime) return true

    // 检查是否在60秒内
    const waitTime = Date.now() - parseInt(lastSendTime)
    return waitTime >= 60000
  }

  startCountdown(startTime = null) {
    const now = Date.now()
    const phone = this.phoneTarget.value
    const lastSendTime = startTime || parseInt(localStorage.getItem(`lastSendTime_${phone}`))
    let seconds = Math.ceil((60000 - (now - lastSendTime)) / 1000)

    if (seconds <= 0) {
      this.sendButtonTarget.disabled = false
      this.sendButtonTarget.textContent = 'Send Code'
      return
    }

    this.sendButtonTarget.disabled = true
    const timer = setInterval(() => {
      seconds--
      this.sendButtonTarget.textContent = `Try again in ${seconds} seconds`

      if (seconds <= 0) {
        clearInterval(timer)
        this.sendButtonTarget.disabled = false
        this.sendButtonTarget.textContent = 'Send Code'
      }
    }, 1000)
  }

  checkLastSendTime(phone) {
    if (!phone) return

    const lastSendTime = localStorage.getItem(`lastSendTime_${phone}`)
    if (lastSendTime && !this.canSend(phone)) {
      this.startCountdown(parseInt(lastSendTime))
    }
  }
}
