import "whatwg-fetch";
import { Controller } from "stimulus"

export default class SecondModal extends Controller {
  connect() {
    this.popupModal = $(`${this.modalTarget}`);

    if (this.isCloseReload) {
      this.popupModal.on("hidden.bs.modal", this.closeReloadHandler);
    }
    else if (this.isTriggerEvent) {
      this.popupModal.on("hidden.bs.modal", this.triggerEventHandler);
    }
    else {
      this.popupModal.on("hidden.bs.modal", this.modalHideHandler);
    }

    if (this.isStatic) {
      this.popupModal.modal({
        backdrop: 'static',
        keyboard: false
      })
    }

    if (this.jumpOut) {
      this.popup();
    }
  }

  popup() {
    this.popupModal.modal("show");
    if (this.path) {
      this.loadModal();
    }
  }

  loadModal() {
    fetch(this.path, {
      headers: { "X-Requested-With": "XMLHttpRequest" }
    }).
      then((response) => response.text()).
      then((html) => {
        requestAnimationFrame(() => {
          this.popupModal.html(html);
        });
      });
  }

  modalHideHandler = () => {
    console.log("modalHideHandler")
    this.popupModal.html("");
  }

  closeReloadHandler = () => {
    window.location.reload();
  }

  triggerEventHandler = () => {
    const eventName = this.data.get("trigger-event");
    if (eventName) {
      const customEvent = new CustomEvent(eventName, {
        bubbles: true,
        cancelable: true,
        detail: { modalController: this }
      });
      this.element.dispatchEvent(customEvent);
    }
  }

  get path() {
    return this.data.get("path");
  }

  get modalTarget() {
    return this.data.get("target");
  }

  get jumpOut() {
    return this.data.get("jumpOut");
  }

  get isStatic() {
    return this.data.get("static");
  }

  get isCloseReload() {
    return this.data.get("close-reload");
  }

  get isTriggerEvent() {
    return this.data.get("trigger-event");
  }
}
