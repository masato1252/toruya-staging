# frozen_string_literal: true

require "line_client"
require "message_encryptor"

module SocialCustomers
  class FromOmniauth < ActiveInteraction::Base
    object :auth, class: OmniAuth::AuthHash
    hash :param, strip: false
    string :who, default: nil

    def execute
      social_account = SocialAccount.find(MessageEncryptor.decrypt(param["oauth_social_account_id"]))

      social_customer = nil
      with_retry do
        social_customer =
          SocialCustomer
          .create_with(social_rich_menu_key: social_account.current_rich_menu_key)
          .find_or_create_by(
            user_id: social_account.user_id,
            social_user_id: auth.uid,
            social_account_id: social_account.id
          )
      end
      social_customer.social_user_name = auth.info.name
      social_customer.social_user_picture_url = auth.info.image

      # LINEからemailを取得（失敗してもログインは続行）
      begin
        line_email = JWT.decode(auth.credentials.id_token, secret, false)[0]["email"]
        # emailをcompositionsに保存してCallbacksControllerで使用
        compositions[:line_email] = line_email if line_email.present?
      rescue => e
        Rollbar.info("LINE email retrieval failed", error: e.message, user_id: social_account.user_id)
        # email取得失敗時も続行
      end

      unless social_customer.is_owner
        social_customer.is_owner = customer_is_owner?
      end
      social_customer.save

      if customer_is_owner?
        profile = social_customer.user.profile
        SocialCustomers::FindOrCreateCustomer.run(
          social_customer: social_customer,
          customer_last_name: profile.last_name,
          customer_first_name: profile.first_name,
          customer_phonetic_last_name: profile.phonetic_last_name,
          customer_phonetic_first_name: profile.phonetic_first_name,
          customer_phone_number: profile.phone_number
        )
      end

      if param["customer_id"]
        SocialCustomers::ConnectWithCustomer.run(
          social_customer: social_customer,
          customer: Customer.find(param["customer_id"])
        )
      end

      social_customer
    end

    private

    def customer_is_owner?
      who == CallbacksController::SHOP_OWNER_CUSTOMER_SELF
    end

    def secret
      if who == CallbacksController::TORUYA_USER
        Rails.application.secrets[:ja][:toruya_line_login_secret]
      elsif who == CallbacksController::TW_TORUYA_USER
        Rails.application.secrets[:tw][:toruya_line_login_secret]
      else
        # Store-specific secret
        social_account = SocialAccount.find(MessageEncryptor.decrypt(param["oauth_social_account_id"]))
        social_account.raw_login_channel_secret
      end
    end
  end
end
