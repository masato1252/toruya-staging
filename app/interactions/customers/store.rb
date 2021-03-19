# frozen_string_literal: true

class Customers::Store < ActiveInteraction::Base
  object :user
  object :current_user, class: User

  hash :params do
    string :id, default: nil
    string :contact_group_id, default: nil
    string :rank_id, default: nil
    string :last_name, default: nil
    string :first_name, default: nil
    string :phonetic_last_name, default: nil
    string :phonetic_first_name, default: nil
    hash :address_details, default: nil do
      string :zip_code, default: nil
      string :region, default: nil
      string :city, default: nil
      string :street1, default: nil
      string :street2, default: nil
    end

    array :phone_numbers_details, default: [] # [{ type: "mobile", value: "123" }]
    array :emails_details, default: [] # [{ type: "mobile", value: "123" }]
    date :birthday, default: nil
    string :custom_id, default: nil
    string :memo, default: nil
  end

  def execute
    if params[:id].present?
      customer = user.customers.find(params[:id])
      customer.attributes = params.merge(updated_at: Time.zone.now, updated_by_user_id: current_user.id)
    else
      customer = user.customers.new(params.merge(updated_by_user_id: current_user.id))
    end

    unless customer.save
      errors.merge!(customer.errors)
    end

    customer
  end
end
