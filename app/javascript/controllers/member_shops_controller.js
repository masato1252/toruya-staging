import { Controller } from "stimulus"

export default class MemberShopsController extends Controller {
  static targets = [
    "form"
  ];

  change = () => {
    $(this.formTarget).submit();
  }
}
