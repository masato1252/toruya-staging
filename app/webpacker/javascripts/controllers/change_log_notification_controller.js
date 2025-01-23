import "whatwg-fetch";
import { Controller } from "stimulus"

export default class ChangeLogNotificationController extends Controller {
  static version = "2.1.3";
  static targets = [
    "content"
  ];

  async connect() {
    this.notification = $(this.element);
    if (await this.isUpdated()) this.hide()
  }

  close() {
    this.update()
    this.hide()
  }

  hide() {
    this.contentTarget.classList.add("display-hidden");
  }

  async isUpdated() {
    if (localStorage.getItem("toruya-release-version") == ChangeLogNotificationController.version)
      return true
    else {
      const response = await fetch(this.changeLogPath);
      const data = await response.json();

      if (data.release_version == ChangeLogNotificationController.version) {
        localStorage.setItem("toruya-release-version", ChangeLogNotificationController.version)
      }

      return data.release_version == ChangeLogNotificationController.version
    }
  }

  update() {
    localStorage.setItem("toruya-release-version", ChangeLogNotificationController.version)
    fetch(this.changeLogPath, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        release_version: ChangeLogNotificationController.version
      })
    })
  }

  get changeLogPath() {
    return this.data.get("path")
  }
}
