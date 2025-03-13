import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  connect() {
    this.button = this.element.querySelector("button");
    this.checkmark = this.button.querySelector("span");
  }

  toggle() {
    let isChecked = false;
    if (this.checkmark.classList.contains("hidden")) {
      this.checkmark.classList.remove("hidden");
      this.button.dataset.state = "checked";
      isChecked = true;
    } else {
      this.checkmark.classList.add("hidden");
      this.button.dataset.state = "unchecked";
      isChecked = false;
    }
    
    // 触发自定义事件，供其他控制器监听
    const event = new CustomEvent("ui--checkbox:toggled", {
      bubbles: true,
      detail: { checked: isChecked }
    });
    this.element.dispatchEvent(event);
  }
}
