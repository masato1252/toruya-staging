import Rails from "rails-ujs";
import _ from "lodash";
import request from "libraries/request";

const IdentificationCodesServices = {
  create: (data) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_generate_code_path(),
      params: {
        phone_number: data.phone_number
      },
      responseType: "json"
    })
  },
  identify: (data) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_identify_code_path(),
      params: _.pick(data, ['phone_number', 'uuid', 'code']),
      responseType: "json"
    })
  }
}

const UsersServices = {
  create: (data) => {
    return request({
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
    return request({
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
  IdentificationCodesServices,
  UsersServices
}
