# frozen_string_literal: true

module OnlineServices
  class Update < ActiveInteraction::Base
    object :online_service, class: "OnlineService"
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :note, default: nil
      string :content_url, default: nil
      string :external_purchase_url, default: nil
      string :solution_type, default: nil
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
          end
        end
      end
    end

    def execute
      online_service.with_lock do
        case update_attribute
        when "name", "note", "external_purchase_url"
          online_service.update(attrs.slice(update_attribute))
        when "content_url"
          online_service.update(content_url: attrs[:content_url], solution_type: attrs[:solution_type])
        when "upsell_sale_page"
          # empty upsell_sale_page_id is invalid input, so pass 0 as delete behavior
          online_service.update(upsell_sale_page_id: attrs[:upsell_sale_page_id].zero? ? nil : attrs[:upsell_sale_page_id])
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
            # TODO: Should not able to delete it?
            # TODO: Existing able to change end time? subscription to others, others to subscription
            attrs[:bundled_services].each do |bundled_service_attrs|
              bundled_service = online_service.bundled_services.find_or_initialize_by(online_service_id: bundled_service_attrs[:id])
              is_new_bundled_service = bundled_service.new_record?

              bundled_service.assign_attributes(
                end_at: bundled_service_attrs.dig(:end_time, :end_time_date_part),
                end_on_days: bundled_service_attrs.dig(:end_time, :end_on_days),
                end_on_months: bundled_service_attrs.dig(:end_time, :end_on_months)
              )

              if bundled_service.save && is_new_bundled_service
                online_service.online_service_customer_relations.available.each do |bundler_relation|
                  Sales::OnlineServices::ApproveBundledService.perform_later(bundled_service: bundled_service, bundler_relation: bundler_relation)
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
  end
end
