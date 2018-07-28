import { Controller } from "stimulus"

export default class AtomicRequestsController extends Controller {
  static linkSelector = "a"
  static remoteSelector = "form[data-remote], a[data-remote]"
  static formSelector = "form"
  static lockName = "atomic-lock"

  connect() {
    $(document).on("click", AtomicRequestsController.linkSelector, (event) => {
      const link = $(this)

      if (this.notRemoteRequest(link) && !this.canMakeAtomicRequest(link)) {
        event.preventDefault()
      }
    })

    $(document).on("submit", AtomicRequestsController.formSelector, () => {
      const form = $(this)

      if (this.notRemoteRequest(form)) {
        return this.canMakeAtomicRequest(form)
      }
    })

    $(document).on("ajax:beforeSend", AtomicRequestsController.remoteSelector, () => {
      const element = $(this)

      return this.canMakeAtomicRequest(element)
    })

    $(document).on("ajax:complete", AtomicRequestsController.remoteSelector, () => {
      const element = $(this)

      return this.setAtomicLock(element, false)
    })
  }

  notRemoteRequest = (element) => {
    return element.not(AtomicRequestsController.remoteSelector)
  }

  canMakeAtomicRequest = (element) => {
    if (element.data(AtomicRequestsController.lockName)) {
      return false
    }
    else {
      return this.setAtomicLock(element)
    }
  }

  setAtomicLock = (element, value) => {
    if (value === null || value === undefined) {
      value = true;
    }

    element.data(AtomicRequestsController.lockName, value)
    return value
  }
}
