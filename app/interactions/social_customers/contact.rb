# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class Contact < ActiveInteraction::Base
    object :social_customer
    string :content
    string :last_name, default: nil
    string :first_name, default: nil

    validate :validate_new_customer

    def execute
      unless social_customer.customer_id
        ApplicationRecord.transaction do
          customer = compose(
            Customers::Create,
            user: social_customer.user,
            customer_last_name: last_name,
            customer_first_name: first_name
          )
          social_customer.update!(customer_id: customer.id)
        end
      end

      SocialMessages::Create.run(
        social_customer: social_customer,
        content: content,
        readed: false,
        message_type: SocialMessage.message_types[:customer]
      )

      # if (Rails.env.production? && social_customer.social_account&.line_settings_verified?) || Rails.env.test?
      #   LineClient.send(social_customer, I18n.t("contact_page.message_sent.line_content"))
      # end
    end

    private

    def validate_new_customer
      if !social_customer.customer_id && first_name.blank?
        errors.add(:base, :name_required)
      end
    end
  end
end
