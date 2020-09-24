import axios from "axios";
import Rails from "rails-ujs";
import _ from "lodash";

const identification_codes = {
  create: (data) => {
    return axios({
      method: "GET",
      url: Routes.lines_user_bot_generate_code_path(),
      params: {
        phone_number: data.phone_number
      },
      responseType: "json"
    })
  },
  identify: (data) => {
    return axios({
      method: "GET",
      url: Routes.lines_user_bot_identify_code_path(),
      params: _.pick(data, ['phone_number', 'uuid', 'code']),
      responseType: "json"
    })
  }
}

const users = {
  create: (data) => {
    return axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_create_user_path(),
      data: _.pick(data, ['first_name', 'last_name', 'phone_number', 'email', 'phonetic_last_name', 'phonetic_first_name', 'uuid', 'referral_token']),
      responseType: "json"
    })
  },
  createShop: (data) => {
    return axios({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_create_shop_profile_path(),
      data: _.pick(data, ['zip_code', 'region', 'city', 'street1', 'street2']),
      responseType: "json"
    })
  }
}

export {
  identification_codes,
  users
}
