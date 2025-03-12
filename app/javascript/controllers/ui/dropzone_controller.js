import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["fileInput"];
  connect() {
    this.element.addEventListener("dragover", this.preventDragDefaults);
    this.element.addEventListener("dragenter", this.preventDragDefaults);
  }

  disconnect() {
    this.element.removeEventListener("dragover", this.preventDragDefaults);
    this.element.removeEventListener("dragenter", this.preventDragDefaults);
  }

  preventDragDefaults(e) {
    e.preventDefault();
    e.stopPropagation();
  }

  trigger() {
    this.fileInputTarget.click();
  }

  acceptFiles(event) {
    event.preventDefault();
    const files = event.dataTransfer ? event.dataTransfer.files : event.target.files;
    [...files].forEach((file) => {
      this.uploadFile(file);
    });
  }

  uploadFile(file) {
    const uploadUrl = this.element.dataset.uploadUrl;
    const fileParamName = this.element.dataset.fileParamName || "file";
    const redirectUrl = this.element.dataset.redirectUrl;

    if (!uploadUrl) {
      console.error("No upload URL provided");
      return;
    }

    const formData = new FormData();
    formData.append(fileParamName, file);

    fetch(uploadUrl, {
      method: "POST",
      body: formData,
      headers: {
        "X-CSRF-Token": document.querySelector("[name='csrf-token']").content
      },
      credentials: 'same-origin'
    })
      .then(response => response.json())
      .then(data => {
        if (data.success && redirectUrl) {
          window.location.href = redirectUrl;
        }
        // 触发自定义事件,让父组件可以处理上传完成后的行为
        const event = new CustomEvent('upload:complete', {
          detail: { response: data }
        });
        this.element.dispatchEvent(event);
      })
      .catch(error => {
        console.error('Upload failed:', error);
        const event = new CustomEvent('upload:error', {
          detail: { error }
        });
        this.element.dispatchEvent(event);
      });
  }
}
