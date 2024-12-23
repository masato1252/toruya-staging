# frozen_string_literal: true

module OnlineServices
  class Update < ActiveInteraction::Base
    object :online_service, class: "OnlineService"
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :internal_name, default: nil
      string :note, default: nil
      string :content_url, default: nil
      string :external_purchase_url, default: nil
      string :solution_type, default: nil
      boolean :customer_address_required, default: false
      string :company_type, default: nil
      integer :company_id, default: nil
      integer :upsell_sale_page_id, default: nil
      hash :start_time, default: nil do
        string :start_time_date_part, default: nil
      end
      hash :end_time, default: nil do
        integer :end_on_days, default: nil
        string :end_time_date_part, default: nil
      end
      hash :message_template, default: nil do
        file :picture, default: nil
        string :content, default: nil
      end
      array :bundled_services, default: nil do
        hash do
          integer :id
          hash :end_time, default: nil do
            integer :end_on_days, default: nil
            integer :end_on_months, default: nil
            string :end_time_date_part, default: nil
            string :end_type, default: nil
          end
        end
      end
    end

    validate :validate_bundled_services, if: -> { update_attribute == "bundled_services" }

    def execute
      online_service.with_lock do
        case update_attribute
        when "name", "note", "external_purchase_url", "internal_name", "customer_address_required"
          online_service.update(attrs.slice(update_attribute))
        when "content_url"
          online_service.update(content_url: attrs[:content_url], solution_type: attrs[:solution_type])
        when "upsell_sale_page"
          # empty upsell_sale_page_id is invalid input, so pass 0 as delete behavior
          online_service.update(upsell_sale_page_id: attrs[:upsell_sale_page_id]&.zero? ? nil : attrs[:upsell_sale_page_id])
        when "company"
          online_service.update(company_type: attrs[:company_type], company_id: attrs[:company_id])
        when "end_time"
          online_service.update(
            end_at: attrs[:end_time][:end_time_date_part] ? Time.zone.parse(attrs[:end_time][:end_time_date_part]).end_of_day : nil,
            end_on_days: attrs[:end_time][:end_on_days]
          )
        when "start_time"
          online_service.update(
            start_at: attrs[:start_time][:start_time_date_part] ? Time.zone.parse(attrs[:start_time][:start_time_date_part]).beginning_of_day : nil
          )
        when "start_at"
          online_service.update(start_at: attrs[:start_at_date_part] ? Time.zone.parse("#{attrs[:start_at_date_part]}-#{attrs[:start_at_time_part]}") : nil)
        when "message_template"
          message = online_service.message_template || online_service.build_message_template(scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_MESSAGE_TEMPLATE)
          message.content = attrs&.dig(:message_template, :content) || ''
          message.picture = attrs&.dig(:message_template, :picture) if attrs&.dig(:message_template, :picture).present?
          message.save

          errors.merge!(message.errors) if message.errors.present?
        when "bundled_services"
          if attrs[:bundled_services].present?
            # Should able to delete it(YES) => clean the relations
            # Existing able to change end time, but it need to follow the rule
            # when sale page is
            #   one time payment: all bundled services need to have end time
            #   recurring payment: at least one service need to be subscription
            ApplicationRecord.transaction do
              new_bundled_online_service_ids = attrs[:bundled_services].pluck(:id)
              existing_bundled_online_service_ids = online_service.bundled_services.pluck(:online_service_id)
              online_service_ids_delete_required = existing_bundled_online_service_ids - new_bundled_online_service_ids
              bundled_services_delete_required = online_service.bundled_services.where(online_service_id: online_service_ids_delete_required)
              # Cancel the relation for the deleted online_service from bundler
              OnlineServiceCustomerRelation.where(bundled_service_id: bundled_services_delete_required).each do |online_service_customer_relation|
                online_service_customer_relation.pending!
              end
              bundled_services_delete_required.delete_all

              attrs[:bundled_services].each do |bundled_service_attrs|
                bundled_service = online_service.bundled_services.find_or_initialize_by(online_service_id: bundled_service_attrs[:id])
                is_new_bundled_service = bundled_service.new_record?

                bundled_service.assign_attributes(
                  end_at: bundled_service_attrs.dig(:end_time, :end_time_date_part),
                  end_on_days: bundled_service_attrs.dig(:end_time, :end_on_days),
                  end_on_months: bundled_service_attrs.dig(:end_time, :end_on_months),
                  subscription: bundled_service_attrs.dig(:end_time, :end_type) == "subscription"
                )

                if bundled_service.save && is_new_bundled_service
                  online_service.online_service_customer_relations.available.each do |bundler_relation|
                    Sales::OnlineServices::ApproveBundledService.perform_later(bundled_service: bundled_service, bundler_relation: bundler_relation)
                  end
                end
              end
            end
          end
        end

        if online_service.errors.present?
          errors.merge!(online_service.errors)
        end

        online_service
      end
    end

    private

    def validate_bundled_services
      SalePage.where(product: online_service).each do |sale_page|
        if sale_page.recurring_prices.present?
          # At least one of service is a subscription
          if attrs[:bundled_services].none? { |bundled_service_attrs| bundled_service_attrs.dig(:end_time, :end_type) == "subscription" }
            errors.add(:attrs, :bundle_services_subscription_required)
          end
        else
          # None of services should be a subscription
          if attrs[:bundled_services].any? { |bundled_service_attrs| bundled_service_attrs.dig(:end_time, :end_type) == "subscription" }
            errors.add(:attrs, :bundle_services_all_end_time_required)
          end
        end
      end
    end
  end
end
