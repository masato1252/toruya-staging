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
    array :tags, default: []
  end

  def execute
    if params[:id].present?
      customer = user.customers.find(params[:id])
      customer.attributes = params.merge(updated_at: Time.zone.now, updated_by_user_id: current_user.id, tags: params[:tags].map { |tag| tag[:text] })
    else
      customer = user.customers.new(params.merge(updated_by_user_id: current_user.id))
    end

    customer.contact_group_id = user.contact_groups.first&.id if customer.contact_group_id.nil?
    unless customer.save
      customer.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
    user.user_setting&.update(customer_tags: Array.wrap(user.user_setting&.customer_tags || []).concat(params[:tags].map { |tag| tag[:text] }).uniq.compact)

    # first time create customer manually
    if user.customers.left_outer_joins(:social_customer).where("social_customers.id is NULL").count == 1
      Notifiers::Users::Customers::FirstManuallyCreation.run(receiver: current_user)
    end

    customer
  end
end
