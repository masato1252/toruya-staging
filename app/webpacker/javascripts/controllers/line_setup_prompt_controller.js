import { Controller } from "stimulus"

const STORAGE_KEY_PREFIX = "line_setup_prompt_shown"

export default class extends Controller {
  connect() {
    const status = this.data.get("status")
    if (!status || status === "complete") return

    const ownerId = this.data.get("owner-id")
    const storageKey = ownerId ? `${STORAGE_KEY_PREFIX}_${ownerId}` : STORAGE_KEY_PREFIX

    if (sessionStorage.getItem(storageKey) === "1") return

    sessionStorage.setItem(storageKey, "1")
    $("#lineSetupPromptModal").modal("show")
  }
}
