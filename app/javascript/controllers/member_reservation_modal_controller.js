import { Controller } from "stimulus"

export default class MemberReservationModal extends Controller {
  connect() {
    const reservationModal = $(`${this.modalTarget}`);

    reservationModal.modal("show");
  }

  get modalTarget(): string {
    return this.data.get("target");
  }
}
