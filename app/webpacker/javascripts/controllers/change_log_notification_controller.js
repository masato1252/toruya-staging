import "whatwg-fetch";
import { Controller } from "stimulus"

export default class ChangeLogNotificationController extends Controller {
  static version = "2.0.2";
  static targets = [
    "content"
  ];

  connect() {
    this.notification = $(this.element);
    if (this.knewUpdated()) this.hide()
  }

  close() {
    this.updated()
    this.hide()
  }

  hide() {
    this.contentTarget.classList.add("display-hidden");
  }

  knewUpdated() {
    return localStorage.getItem("toruya-release-version") == ChangeLogNotificationController.version
  }

  updated() {
    return localStorage.setItem("toruya-release-version", ChangeLogNotificationController.version)
  }
}
