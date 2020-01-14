import "whatwg-fetch";
import { Controller } from "stimulus"

export default class Modal extends Controller {
  connect() {
    this.popupModal = $(`${this.modalTarget}`);
    this.popupModal.on("hidden.bs.modal", this.modalHideHandler);

    if (this.jumpOut) {
      this.popup();
    }
  }

  popup() {
    this.popupModal.modal("show");
    this.loadModal();
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
    this.popupModal.html("");
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
}
