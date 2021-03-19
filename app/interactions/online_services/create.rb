# frozen_string_literal: true

module OnlineServices
  class Create < ActiveInteraction::Base
    object :user
    string :name
    string :selected_goal
    string :selected_solution
    hash :end_time do
      integer :end_on_days, default: nil
      string :end_time_date_part, default: nil
    end
    hash :upsell, default: nil do
      integer :sale_page_id, default: nil
    end
    hash :content do
      string :url, default: nil
    end
    hash :selected_company do
      string :type
      integer :id
    end

    def execute
      ApplicationRecord.transaction do
        online_service = user.online_services.create(
          name: name,
          goal_type: selected_goal,
          solution_type: selected_solution,
          end_at: end_time[:end_time_date_part] ? Time.zone.parse(end_time[:end_time_date_part]).end_of_day : nil,
          end_on_days: end_time[:end_on_days],
          content: content,
          upsell_sale_page_id: upsell[:sale_page_id],
          company_type: selected_company[:type],
          company_id: selected_company[:id],
          slug: SecureRandom.alphanumeric(10)
        )

        if online_service.errors.present?
          errors.merge!(online_service.errors)
        end

        online_service
      end
    end
  end
end
