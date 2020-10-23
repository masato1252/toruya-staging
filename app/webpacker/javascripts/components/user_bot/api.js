import Rails from "rails-ujs";
import _ from "lodash";
import request from "libraries/request";

const IdentificationCodesServices = {
  create: (data) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_generate_code_path({format: "json"}),
      params: {
        phone_number: data.phone_number
      },
      responseType: "json"
    })
  },
  identify: (params) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_identify_code_path({format: "json"}),
      params: params,
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
      url: Routes.lines_user_bot_create_user_path({format: "json"}),
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
      url: Routes.lines_user_bot_create_shop_profile_path({format: "json"}),
      data: _.pick(data, ['zip_code', 'region', 'city', 'street1', 'street2']),
      responseType: "json"
    })
  },
  checkShop: () => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_check_shop_profile_path({format: "json"}),
      responseType: "json"
    })
  },
  schedules: (date) => {
    return request({
      method: "GET",
      url: Routes.personal_working_schedule_lines_user_bot_calendars_path({date: date, format: "json"}),
      responseType: "json"
    })
  }
}

const ReservationServices = {
  create: (shop_id, data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_shop_reservations_path(shop_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  update: (shop_id, reservation_id, data) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_shop_reservation_path(shop_id, reservation_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  validate: (shop_id, reservation_id = null, data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.validate_lines_user_bot_shop_reservations_path(shop_id, reservation_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  addCustomer: ({shop_id, data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.add_customer_lines_user_bot_shop_reservations_path(shop_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  }
}

const CustomerServices = {
  recent: (last_updated_id = null, last_updated_at = null) => {
    return request({
      method: "GET",
      url: Routes.recent_lines_user_bot_customers_path({format: "json"}),
      params: {
        last_updated_at,
        last_updated_id
      },
      responseType: "json"
    })
  },
  search: ({page, keyword}) => {
    return request({
      method: "GET",
      url: Routes.search_lines_user_bot_customers_path({format: "json"}),
      params: {
        page,
        keyword
      },
      responseType: "json"
    })
  },
  filter: ({page, pattern_number}) => {
    return request({
      method: "GET",
      url: Routes.filter_lines_user_bot_customers_path({format: "json"}),
      params: {
        page,
        pattern_number: pattern_number || 0
      },
      responseType: "json"
    })
  },
  reservations: ({customer_id}) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_customer_reservations_path({format: "json"}),
      params: {
        customer_id,
      },
      responseType: "json"
    })
  },
  save: (data) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.save_lines_user_bot_customers_path({format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  messages: (id) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_customer_messages_path({format: "json"}),
      params: {
        id,
      },
      responseType: "json"
    })
  },
  toggle_reminder_premission: (customer_id) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.toggle_reminder_premission_lines_user_bot_customers_path({format: "json"}),
      data: {
        id: customer_id,
      },
      responseType: "json"
    })
  },
  find_duplicate_customers: ({last_name, first_name}) => {
    return request({
      method: "GET",
      url: Routes.find_duplicate_customers_lines_user_bot_customers_path({format: "json"}),
      params: {
        last_name,
        first_name
      },
      responseType: "json"
    })
  }
}

export {
  IdentificationCodesServices,
  UsersServices,
  ReservationServices,
  CustomerServices
}
