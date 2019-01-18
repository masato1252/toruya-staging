import { Controller } from "stimulus"

export default class CollapseController extends Controller {
  static targets = [
    "content",
    "openToggler",
    "closeToggler"
  ];

  connect() {
  }

  toggle = () => {
    if (this.isOpen) {
      this.close();
    } else {
      this.open();
    }
  }

  close = () => {
    this.status = "closed";
    this.contentTarget.classList.add("display-hidden");
    this.openTogglerTarget.classList.add("display-hidden");
    this.closeTogglerTarget.classList.remove("display-hidden");
  }

  open = () => {
    this.status = "open";
    this.contentTarget.classList.remove("display-hidden");
    this.openTogglerTarget.classList.remove("display-hidden");
    this.closeTogglerTarget.classList.add("display-hidden");
  }

  get isOpen() {
    return this.status === "open"
  }

  get status() {
    return this.data.get("status");
  }

  set status(value) {
    this.data.set("status", value)
  }
}
