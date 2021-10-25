# frozen_string_literal: true

module OnlineServices
  class Update < ActiveInteraction::Base
    object :online_service, class: "OnlineService"
    string :update_attribute

    hash :attrs, default: nil do
      string :name, default: nil
      string :content_url, default: nil
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
    end

    def execute
      online_service.with_lock do
        case update_attribute
        when "name"
          online_service.update(attrs.slice(update_attribute))
        when "content_url"
          online_service.update(content_url: attrs[:content_url], solution_type: attrs[:solution_type])
        when "upsell_sale_page"
          online_service.update(upsell_sale_page_id: attrs[:upsell_sale_page_id])
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
        end

        if online_service.errors.present?
          errors.merge!(online_service.errors)
        end
      end
    end
  end
end
