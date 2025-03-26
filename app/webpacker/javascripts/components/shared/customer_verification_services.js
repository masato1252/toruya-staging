"use strict";

import Rails from "rails-ujs";
import _ from "lodash";
import request from "libraries/request";
import Routes from 'js-routes.js'

export const CustomerVerificationServices = {
  generateVerificationCode: (data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.customer_verification_generate_verification_code_path({format: "json"}),
      data: {
        customer_phone_number: data.customer_phone_number,
        user_id: data.user_id
      },
      responseType: "json"
    })
  },

  verifyCode: (data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.customer_verification_verify_code_path({format: "json"}),
      data: _.pick(data, ['user_id', 'customer_phone_number', 'uuid', 'code']),
      responseType: "json"
    })
  },

  createOrUpdateCustomer: (data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.customer_verification_create_or_update_customer_path({format: "json"}),
      data: _.pick(data, [
        'user_id',
        'customer_social_user_id',
        'customer_last_name',
        'customer_first_name',
        'customer_phonetic_last_name',
        'customer_phonetic_first_name',
        'customer_phone_number',
        'customer_email',
        'uuid'
      ]),
      responseType: "json"
    })
  }
};

export default CustomerVerificationServices;