# frozen_string_literal: true

class Customers::Store < ActiveInteraction::Base
  ASSIGNABLE_ATTRIBUTES = %i[
    contact_group_id rank_id last_name first_name phonetic_last_name phonetic_first_name
    address_details phone_numbers_details emails_details birthday custom_id memo tags
  ].freeze

  object :user
  object :current_user, class: User
  # Use a plain hash so partial updates (e.g. booking) do not fill absent keys with nil defaults.
  record :params, class: Hash, default: {}

  def execute
    customer_params = normalize_params(params)
    tag_texts = customer_params[:tags]&.map { |tag| tag[:text] || tag["text"] }

    if customer_params[:id].present?
      customer = user.customers.find(customer_params[:id])
      merge_attrs = customer_params.except(:id, :tags).slice(*ASSIGNABLE_ATTRIBUTES)
      merge_attrs[:tags] = tag_texts if tag_texts
      customer.assign_attributes(
        merge_attrs.merge(updated_at: Time.zone.now, updated_by_user_id: current_user.id)
      )
    else
      merge_attrs = customer_params.except(:tags).slice(*ASSIGNABLE_ATTRIBUTES)
      merge_attrs[:tags] = tag_texts || []
      merge_attrs[:phone_numbers_details] ||= []
      merge_attrs[:emails_details] ||= []
      customer = user.customers.new(merge_attrs.merge(updated_by_user_id: current_user.id))
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

  def normalize_params(raw)
    attrs = raw.deep_symbolize_keys

    if attrs[:birthday].is_a?(String)
      attrs[:birthday] = attrs[:birthday].present? ? Date.parse(attrs[:birthday]) : nil
    end

    attrs
  end

  def normalize_email(email)
    email.to_s.gsub('＠', '@')
  end
end
