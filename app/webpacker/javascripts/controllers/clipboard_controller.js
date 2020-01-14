import { Controller } from "stimulus";
import clipboardCopy from "clipboard-copy";

export default class ClipboardController extends Controller {
  clipboardSuccessHandler = (event) => {
    $(this.element).tooltip({
      title: this.popup_text || "Copied!"
    }).tooltip("show")
  };

  copy = () => {
    clipboardCopy(this.copied_text).then((success) => {
      this.clipboardSuccessHandler()
    });
  }

  get popup_text() {
    return this.data.get("popupText");
  }

  get copied_text() {
    return this.data.get("text");
  }
}
