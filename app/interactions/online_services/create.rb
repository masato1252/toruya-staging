# frozen_string_literal: true

module OnlineServices
  class Create < ActiveInteraction::Base
    set_callback :type_check, :before do
      self.message_template = nil if message_template&.dig(:picture).blank? || message_template&.dig(:content).blank?
    end

    object :user
    string :name
    string :selected_goal
    string :selected_solution, default: nil # course and membership doesn't provide solution, their solution is their lessons or episodes
    string :content_url, default: nil
    hash :end_time, default: nil do
      integer :end_on_days, default: nil
      string :end_time_date_part, default: nil
    end
    hash :upsell, default: nil do
      integer :sale_page_id, default: nil
    end
    hash :selected_company do
      string :type
      integer :id
    end
    hash :message_template, default: nil do
      file :picture, default: nil
      string :content, default: nil
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
          upsell_sale_page_id: upsell&.dig(:sale_page_id),
          company_type: selected_company[:type],
          company_id: selected_company[:id],
          slug: SecureRandom.alphanumeric(10)
        )

        if online_service.errors.present?
          errors.merge!(online_service.errors)
          return
        end

        if message_template&.dig(:content) || message_template&.dig(:picture)
          message = CustomMessage.create(
            service: online_service,
            scenario: CustomMessage::ONLINE_SERVICE_MESSAGE_TEMPLATE,
            content: message_template[:content],
            picture: message_template[:picture]
          )
          errors.merge!(message.errors) if message.errors.present?
        end

        if online_service.recurring_charge_required?
          stripe_product = compose(OnlineServices::CreateStripeProduct, online_service: online_service)
          online_service.update!(stripe_product_id: stripe_product.id)
        end

        online_service
      end
    end

    private

    def validate_content_url
      if content_url.blank? && not_membership_or_course
        errors.add(:content_url, :invalid)
      end
    end

    def validate_solution
      if selected_solution.blank? && not_membership_or_course
        errors.add(:selected_solution, :invalid)
      end
    end

    def not_membership_or_course
      [OnlineService.goal_types[:membership], OnlineService.goal_types[:course]].exclude?(selected_goal)
    end
  end
end
