import { Controller } from "stimulus";
import ClipboardJS from "clipboard";

export default class ClipboardController extends Controller {
  connect() {
    // Clipboard, by default, looks for the "data-clipboard-text" attribute on
    // the element.
    this.clipboard = new ClipboardJS(this.element);
    this.clipboard.on("success", this.clipboardSuccessHandler);
  }

  clipboardSuccessHandler = (event) => {
    $(this.element).tooltip({
      title: this.popup_text || "Copied!"
    }).tooltip("show")
  };

  get popup_text() {
    return this.data.get("popupText");
  }
}
