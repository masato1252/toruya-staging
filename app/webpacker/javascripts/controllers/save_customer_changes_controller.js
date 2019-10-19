import { Controller } from "stimulus"

export default class SaveCustomerChangesController extends Controller {
  connect() {
    this.element.addEventListener("ajax:complete", this.ajaxCompleteHandler);
  }

  disconnect() {
    this.element.removeEventListener("ajax:complete", this.ajaxCompleteHandler);
  }

  ajaxCompleteHandler = () => {
    $('#dummyModal2').modal('hide');
  };
}
