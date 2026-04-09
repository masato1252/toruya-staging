import { Controller } from "stimulus"

const STORAGE_KEY = "line_setup_prompt_dismissed_at"

export default class extends Controller {
  connect() {
    const status = this.data.get("status")
    if (!status || status === "complete") return

    const today = new Date().toISOString().slice(0, 10)
    if (localStorage.getItem(STORAGE_KEY) === today) return

    this.modal = $("#lineSetupPromptModal")
    this.modal.on("hidden.bs.modal", this.onDismiss)
    this.modal.modal("show")
  }

  disconnect() {
    if (this.modal) {
      this.modal.off("hidden.bs.modal", this.onDismiss)
    }
  }

  onDismiss = () => {
    const today = new Date().toISOString().slice(0, 10)
    localStorage.setItem(STORAGE_KEY, today)
  }
}
