import { Controller } from "stimulus"
import axios from "axios";
import Rails from "rails-ujs";

export default class WebPushSubscriber extends Controller {
  static targets = [
    "askArea",
    "deniedArea",
  ];

  connect() {
    console.log("WebPushSubscriber")

    if (!("Notification" in window)) {
      console.error("This browser does not support desktop notification")
      this.hidePermissionView()
    }
    else if (Notification.permission === "granted") {
      this.allowPermissionView()
    }
    else if (Notification.permission === "denied") {
      this.deniedPermissionView()
    }
    else {
      this.askPermissionView()
    }
  }

  askPermission() {
    if (!("Notification" in window)) {
      console.error("This browser does not support desktop notification");
    }
    // Let's check whether notification permissions have already been granted
    else if (Notification.permission === "granted") {
      console.log("Permission to receive notifications has been granted");
      this.getKeys();
      this.allowPermissionView();
    }
    // Otherwise, we need to ask the user for permission
    else if (Notification.permission !== 'denied') {
      Notification.requestPermission().then((permission) => {
        // If the user accepts, let's create a notification
        if (permission === "granted") {
          console.log("Permission to receive notifications has been granted");
          this.getKeys();
          this.allowPermissionView();
        }
        else if (permission === "denied") {
          this.deniedPermissionView();
        }
      });
    }
  }

  async getKeys() {
    if (navigator.serviceWorker) {
      navigator.serviceWorker.register('/serviceworker.js', {scope: './'})

      const registration = await navigator.serviceWorker.ready
      let subscription = await registration.pushManager.getSubscription()

      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: this.publicKey
        });

        this.saveSubscription(subscription)
      }
    }
  }

  askPermissionView() {
    this.deniedAreaTarget.classList.add("display-hidden")
  }

  allowPermissionView() {
    this.askAreaTarget.classList.add("display-hidden")
    this.deniedAreaTarget.classList.add("display-hidden")
  }

  hidePermissionView() {
    this.allowPermissionView()
  }

  deniedPermissionView() {
    this.askAreaTarget.classList.add("display-hidden")
    this.deniedAreaTarget.classList.add("display-block")
  }

  saveSubscription(subscription) {
    axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: this.saveSubscriptionPath,
      data: { subscription },
      responseType: "json"
    })
  }

  get publicKey() {
    return new Uint8Array(JSON.parse(this.data.get("key")));
  }

  get saveSubscriptionPath() {
    return this.data.get("path");
  }
}
