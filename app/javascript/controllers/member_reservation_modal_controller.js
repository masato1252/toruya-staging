import "bootstrap"
import $ from "jquery";
import { Controller } from "stimulus"

export default class MemberReservationModal extends Controller {
  connect() {
    const reservationModal = $(`${this.modalTarget}`);
    const reservationDialog = reservationModal.find(".modal-dialog");

    reservationModal.on('hidden.bs.modal', function (e) {
      reservationDialog.removeAttr("style");
    })
    reservationDialog.css({"margin-top": "90px"});
    reservationModal.modal("show");
  }

  get modalTarget(): string {
    return this.data.get("target");
  }
}
