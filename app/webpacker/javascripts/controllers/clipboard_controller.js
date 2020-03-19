import { Controller } from "stimulus";
import clipboardCopy from "clipboard-copy";

export default class ClipboardController extends Controller {
  clipboardSuccessHandler = (event) => {
    const tooltip = $(this.element).tooltip({
      trigger: "manual",
      title: this.popup_text || "Copied!",
    })

    tooltip.tooltip("show")

    setTimeout(function() {
      tooltip.tooltip("hide")
    }, 2000);
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
