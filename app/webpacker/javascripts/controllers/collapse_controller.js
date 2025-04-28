import { Controller } from "stimulus"

export default class CollapseController extends Controller {
  static targets = [
    "content",
    "simpleContent",
    "openToggler",
    "closeToggler",
  ];

  connect() {
    if (this.isOpen) {
      this.open();
    } else {
      this.close();
    }
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

    if (this.hasContentTarget) {
      this.contentTarget.classList.add("display-hidden");
    }

    if (this.hasSimpleContentTarget) {
      this.simpleContentTarget.classList.remove("display-hidden");
    }

    if (this.hasOpenTogglerTarget) {
      this.openTogglerTarget.classList.add("display-hidden");
    }

    if (this.hasCloseTogglerTarget) {
      this.closeTogglerTarget.classList.remove("display-hidden");
    }
  }

  open = () => {
    this.status = "open";

    if (this.hasContentTarget) {
      this.contentTarget.classList.remove("display-hidden");
    }

    if (this.hasSimpleContentTarget) {
      this.simpleContentTarget.classList.add("display-hidden");
    }

    if (this.hasOpenTogglerTarget) {
      this.openTogglerTarget.classList.remove("display-hidden");
    }

    if (this.hasCloseTogglerTarget) {
      this.closeTogglerTarget.classList.add("display-hidden");
    }
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
