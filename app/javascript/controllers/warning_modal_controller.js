import "whatwg-fetch";
import { Controller } from "stimulus"

export default class WarningModal extends Controller {
  connect() {
    this.popupModal = $(`${this.modalTarget}`);
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

  get path(): string {
    return this.data.get("warningPath");
  }

  get modalTarget(): string {
    return this.data.get("target");
  }
}
