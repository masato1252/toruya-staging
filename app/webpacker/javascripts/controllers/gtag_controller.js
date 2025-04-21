import { Controller } from "stimulus"

export default class GtagController extends Controller {
  sendEvent(event) {
    const eventValue = this.data.get("eventValue")
    const eventCategory = this.data.get("eventCategory")
    const eventLabel = this.data.get("eventLabel")

    window.gtag('event', eventValue, {
      'locale': I18n.locale || I18n.defaultLocale,
      'item_category': eventCategory,
      'event_category': eventCategory,
      'content_type': eventCategory,
      'item_name': eventLabel,
      'event_label': eventLabel
    })
  }
}