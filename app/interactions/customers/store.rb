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
    array :tags, default: nil
  end

  def execute
    tag_texts = params[:tags]&.map { |tag| tag[:text] }

    if params[:id].present?
      customer = user.customers.find(params[:id])
      merge_attrs = params.except(:tags).merge(updated_at: Time.zone.now, updated_by_user_id: current_user.id)
      merge_attrs[:tags] = tag_texts if tag_texts
      customer.attributes = merge_attrs
    else
      merge_attrs = params.except(:tags).merge(updated_by_user_id: current_user.id)
      merge_attrs[:tags] = tag_texts || []
      customer = user.customers.new(merge_attrs)
    end

    # Normalize email addresses in emails_details
    if customer.emails_details.present?
      customer.emails_details = customer.emails_details.map do |email_detail|
        if email_detail["value"].present?
          email_detail["value"] = normalize_email(email_detail["value"])
        end
        email_detail
      end
    end

    customer.contact_group_id = user.contact_groups.first&.id if customer.contact_group_id.nil?
    unless customer.save
      customer.errors.each do |error|
        errors.add(error.attribute, error.message)
      end
    end
    if tag_texts
      user.user_setting&.update(customer_tags: Array.wrap(user.user_setting&.customer_tags || []).concat(tag_texts).uniq.compact)
    end

    # first time create customer manually
    if user.customers.left_outer_joins(:social_customer).where("social_customers.id is NULL").count == 1
      Notifiers::Users::Customers::FirstManuallyCreation.run(receiver: current_user)
    end

    customer
  end

  private

  def normalize_email(email)
    email.to_s.gsub('＠', '@')
  end
end
