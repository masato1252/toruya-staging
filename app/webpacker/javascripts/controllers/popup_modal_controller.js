import { Controller } from "stimulus"

export default class PopupModal extends Controller {
  connect() {
    const popupModal = $(`${this.modalTarget}`);

    popupModal.modal("show");
  }

  get modalTarget(): string {
    return this.data.get("target");
  }
}
