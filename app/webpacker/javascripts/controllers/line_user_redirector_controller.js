import { Controller } from "stimulus"

export default class LineUserRedirector extends Controller {
  connect() {
    liff
      .init({
        liffId: this.liffId
      })
      .then(() => {
        liff.getProfile()
          .then(profile => {
            window.location.replace(this.url + '/social_service_user_id/' + profile.userId)
          })
          .catch((err) => {
            console.log('error', err);
          });
      })
      .catch((err) => {
      });
  }

  get liffId() {
    return this.data.get("liffId")
  }

  get url() {
    return this.data.get("url")
  }
}
