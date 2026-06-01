import { Controller } from "stimulus"

const STORAGE_KEY_PREFIX = "shop_setup_prompt"

export default class extends Controller {
  connect() {
    if (this.data.get("enabled") !== "true") return

    const userId = this.data.get("user-id")
    const today = new Date().toISOString().slice(0, 10)
    const storageKey = `${STORAGE_KEY_PREFIX}_${userId}_${today}`

    if (localStorage.getItem(storageKey) === "1") return

    localStorage.setItem(storageKey, "1")
    $("#shopSetupPromptModal").modal("show")
  }
}
