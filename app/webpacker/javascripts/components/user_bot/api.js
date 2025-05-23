import Rails from "rails-ujs";
import _ from "lodash";
import request from "libraries/request";
import { serialize } from 'object-to-formdata';
import Routes from 'js-routes.js'

const IdentificationCodesServices = {
  create: (data) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_generate_code_path({format: "json"}),
      params: {
        phone_number: data.phone_number,
        login_type: data.login_type
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
      data: _.pick(data, ['first_name', 'last_name', 'phone_number', 'email', 'phonetic_last_name', 'phonetic_first_name', 'uuid', 'referral_token', 'where_know_toruya', 'what_main_problem']),
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
      data: _.pick(data, ['zip_code', 'region', 'city', 'street1', 'street2', 'company_name', 'company_phone_number']),
      responseType: "json"
    })
  },
  checkShop: ({social_service_user_id, staff_token}) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_check_shop_profile_path(social_service_user_id, { staff_token: staff_token, format: "json" }),
      responseType: "json"
    })
  },
  schedules: ({ business_owner_id, date }) => {
    return request({
      method: "GET",
      url: Routes.personal_working_schedule_lines_user_bot_calendars_path({business_owner_id: business_owner_id, date: date, format: "json"}),
      responseType: "json"
    })
  },
  updateProfile: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_settings_profile_path(data.business_owner_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  }
}

const ReservationServices = {
  create: ({ business_owner_id, shop_id, data }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_shop_reservations_path(business_owner_id, shop_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  update: ({ business_owner_id, shop_id, reservation_id, data }) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_shop_reservation_path(business_owner_id, shop_id, reservation_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  validate: ({ business_owner_id, shop_id, reservation_id, data }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.validate_lines_user_bot_shop_reservations_path(business_owner_id, shop_id, reservation_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  addCustomer: ({ business_owner_id, shop_id, data }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.add_customer_lines_user_bot_shop_reservations_path(business_owner_id, shop_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  schedule: ({ business_owner_id, shop_id, params }) => {
    return request({
      method: "GET",
      url: Routes.schedule_lines_user_bot_shop_reservations_path(business_owner_id, shop_id, {format: "html"}),
      params: params
    })
  }
}

const CustomerServices = {
  details: ({ business_owner_id, customer_id }) => {
    return request({
      method: "GET",
      url: Routes.details_lines_user_bot_customers_path({format: "json"}),
      params: {
        business_owner_id,
        customer_id
      },
      responseType: "json"
    })
  },
  recent: ({ business_owner_id, last_updated_id, last_updated_at }) => {
    return request({
      method: "GET",
      url: Routes.recent_lines_user_bot_customers_path({format: "json"}),
      params: {
        business_owner_id,
        last_updated_at,
        last_updated_id
      },
      responseType: "json"
    })
  },
  search: ({ business_owner_id, page, keyword }) => {
    return request({
      method: "GET",
      url: Routes.search_lines_user_bot_customers_path({format: "json"}),
      params: {
        business_owner_id,
        page,
        keyword
      },
      responseType: "json"
    })
  },
  filter: ({ business_owner_id, page, pattern_number }) => {
    return request({
      method: "GET",
      url: Routes.filter_lines_user_bot_customers_path({format: "json"}),
      params: {
        business_owner_id,
        page,
        pattern_number: pattern_number || 0
      },
      responseType: "json"
    })
  },
  reservations: ({ business_owner_id, customer_id }) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_customer_reservations_path({format: "json"}),
      params: {
        business_owner_id,
        customer_id,
      },
      responseType: "json"
    })
  },
  payments: ({ business_owner_id, customer_id }) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_customer_payments_path({format: "json"}),
      params: {
        business_owner_id,
        customer_id,
      },
      responseType: "json"
    })
  },
  save: ({ business_owner_id, data }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.save_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  messages: ({ business_owner_id, id, oldest_message_at, oldest_message_id }) => {
    return request({
      method: "GET",
      url: Routes.lines_user_bot_customer_messages_path({format: "json"}),
      params: {
        business_owner_id,
        id,
        oldest_message_at,
        oldest_message_id
      },
      responseType: "json"
    })
  },
  delete: ({ business_owner_id, id }) => {
    return request({
      method: "DELETE",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.delete_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      params: {
        id,
      },
      responseType: "json"
    })
  },
  toggle_reminder_permission: ({ business_owner_id, customer_id }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.toggle_reminder_permission_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      data: {
        business_owner_id,
        id: customer_id,
      },
      responseType: "json"
    })
  },
  find_duplicate_customers: ({ business_owner_id, last_name, first_name }) => {
    return request({
      method: "GET",
      url: Routes.find_duplicate_customers_lines_user_bot_customers_path({format: "json"}),
      params: {
        business_owner_id,
        last_name,
        first_name
      },
      responseType: "json"
    })
  },
  reply_message: ({ business_owner_id, customer_id, message, schedule_at, image }) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.reply_message_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      data: serialize({
        business_owner_id,
        customer_id,
        message,
        schedule_at,
        image
      }),
      responseType: "json"
    })
  },
  delete_message: ({ business_owner_id, customer_id, message_id }) => {
    return request({
      method: "DELETE",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.delete_message_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      params: {
        business_owner_id,
        customer_id,
        message_id
      },
      responseType: "json"
    })
  },
  unread_message: ({ business_owner_id, customer_id, message_id }) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.unread_message_lines_user_bot_customers_path({business_owner_id: business_owner_id, format: "json"}),
      params: {
        business_owner_id,
        customer_id,
        message_id
      },
      responseType: "json"
    })
  },
}

const PaymentServices = {
  payPlan: ({token, plan, rank, business_owner_id, payment_intent_id}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_settings_payments_path({format: "json"}),
      data: {
        token,
        plan,
        rank,
        business_owner_id,
        payment_intent_id
      },
      responseType: "json"
    })
  }
}

const BookingPageServices = {
  update: ({booking_page_id, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_booking_page_path(data.business_owner_id, booking_page_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  }
}

const BookingOptionServices = {
  update: ({booking_option_id, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_booking_option_path(data.business_owner_id, booking_option_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  reorder: ({booking_option_id, data}) => {
    return request({
      method: "PATCH",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.reorder_menu_priority_lines_user_bot_booking_option_path(data.business_owner_id, booking_option_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const BookingServices = {
  available_options: ({business_owner_id, shop_id}) => {
    return request({
      method: "GET",
      url: Routes.available_options_lines_user_bot_bookings_path(business_owner_id, {format: "json"}),
      params: {
        business_owner_id,
        shop_id,
      },
      responseType: "json"
    })
  },
  create_booking_page: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.page_lines_user_bot_bookings_path(data.business_owner_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const SocialAccountServices = {
  update: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_settings_social_account_path({format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const ContactServices = {
  make_contact: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_make_contact_path({format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const SaleServices = {
  create_sales_booking_page: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_sales_booking_pages_path(data.business_owner_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
  create_sales_online_service: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_sales_online_services_path(data.business_owner_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
  purchase: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_customers_online_service_purchases_path({format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  update: ({sale_page_id, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_sale_path(data.business_owner_id, sale_page_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
}

const OnlineServices = {
  create_service: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_services_path(data.business_owner_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
  update: ({online_service_id, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_service_path(data.business_owner_id, online_service_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
  demo_message: ({online_service_id, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.demo_message_lines_user_bot_service_path(data.business_owner_id, online_service_id, {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
}

const CommonServices = {
  delete: ({url, data}) => {
    return request({
      method: "DELETE",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: url,
      params: data,
      responseType: "json"
    })
  },
  get: ({url, data}) => {
    return request({
      method: "GET",
      url: url,
      params: data,
      responseType: "json"
    })
  },
  create: ({url, data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: url,
      data: serialize(data),
      responseType: "json"
    })
  },
  update: ({url, data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: url,
      data: serialize(data),
      responseType: "json"
    })
  },
}

const BusinessScheduleServices = {
  update: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.update_lines_user_bot_settings_business_schedules_path(data.business_owner_id, data.shop_id, data.wday, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const ShopServices = {
  update: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
        "content-type": "multipart/form-data"
      },
      url: Routes.lines_user_bot_settings_shop_path(data.business_owner_id, data['id'], {format: "json"}),
      data: serialize(data),
      responseType: "json"
    })
  },
}

const MenuServices = {
  update: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
      },
      url: Routes.lines_user_bot_settings_menu_path(data.business_owner_id, data['id'], {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const SocialUserMessagesServices = {
  create: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
      },
      url: Routes.lines_user_bot_social_user_messages_path({format: "json"}),
      data: data,
      responseType: "json"
    })
  },
}

const CustomMessageServices = {
  update: ({data}) => {
    return request({
      method: "PUT",
      headers: {
        "X-CSRF-Token": Rails.csrfToken()
      },
      url: Routes.lines_user_bot_custom_messages_path(data.business_owner_id, {format: "json"}),
      data: data,
      responseType: "json"
    })
  },
  demo: ({data}) => {
    return request({
      method: "POST",
      headers: {
        "X-CSRF-Token": Rails.csrfToken(),
      },
      url: Routes.demo_lines_user_bot_custom_messages_path(data.business_owner_id),
      data: data,
      responseType: "json"
    })
  },
}

export {
  IdentificationCodesServices,
  UsersServices,
  ReservationServices,
  CustomerServices,
  CommonServices,
  PaymentServices,
  BookingPageServices,
  BookingOptionServices,
  BookingServices,
  SocialAccountServices,
  ContactServices,
  SaleServices,
  OnlineServices,
  BusinessScheduleServices,
  ShopServices,
  MenuServices,
  SocialUserMessagesServices,
  CustomMessageServices,
}
