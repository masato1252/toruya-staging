# frozen_string_literal: true

module OnlineServices
  class Create < ActiveInteraction::Base
    object :user
    string :name
    string :selected_goal
    string :selected_solution, default: nil # course and membership doesn't provide solution, their solution is their lessons or episodes
    string :content_url, default: nil
    string :external_purchase_url, default: nil
    hash :end_time, default: nil do
      integer :end_on_days, default: nil
      string :end_time_date_part, default: nil
    end
    hash :upsell, default: nil do
      integer :sale_page_id, default: nil
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

    validate :validate_content_url
    validate :validate_solution

    def execute
      ApplicationRecord.transaction do
        online_service = user.online_services.create(
          name: name,
          goal_type: selected_goal,
          solution_type: selected_solution.presence || selected_goal,
          end_at: end_time&.dig(:end_time_date_part) ? Time.zone.parse(end_time[:end_time_date_part]).end_of_day : nil,
          end_on_days: end_time&.dig(:end_on_days),
          content_url: content_url,
          external_purchase_url: external_purchase_url,
          upsell_sale_page_id: upsell&.dig(:sale_page_id),
          company: user.profile,
          slug: SecureRandom.alphanumeric(10)
        )

        if online_service.errors.present?
          errors.merge!(online_service.errors)
          return
        end

        if message_template&.dig(:content) || message_template&.dig(:picture)
          message = CustomMessage.create(
            service: online_service,
            scenario: ::CustomMessages::Customers::Template::ONLINE_SERVICE_MESSAGE_TEMPLATE,
            content: message_template[:content] || "",
            picture: message_template[:picture]
          )
          errors.merge!(message.errors) if message.errors.present?
        end

        if bundled_services.present?
          bundled_services.each do |bundled_service|
            online_service.bundled_services.create(
              online_service_id: bundled_service[:id],
              end_at: bundled_service.dig(:end_time, :end_time_date_part),
              end_on_days: bundled_service.dig(:end_time, :end_on_days),
              end_on_months: bundled_service.dig(:end_time, :end_on_months),
              subscription: bundled_service.dig(:end_time, :end_type) == "subscription"
            )
          end
        end

        online_service
      end
    end

    private

    def validate_content_url
      if content_url.blank? && not_membership_or_course_or_bundler
        errors.add(:content_url, :invalid)
      end
    end

    def validate_solution
      if selected_solution.blank? && not_membership_or_course_or_bundler
        errors.add(:selected_solution, :invalid)
      end
    end

    def not_membership_or_course_or_bundler
      [OnlineService.goal_types[:membership], OnlineService.goal_types[:free_course], OnlineService.goal_types[:course], OnlineService.goal_types[:bundler]].exclude?(selected_goal)
    end
  end
end
