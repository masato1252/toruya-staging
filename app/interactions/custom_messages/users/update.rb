# frozen_string_literal: true

module CustomMessages
  module Users
    class Update < ActiveInteraction::Base
      object :custom_message
      string :content
      integer :after_days
      integer :nth_time
      string :flex_template, default: nil
      string :content_type

      def execute
        custom_message.assign_attributes(
          content: content,
          after_days: after_days,
          nth_time: nth_time,
          flex_template: flex_template,
          content_type: content_type,
        )

        if custom_message.valid? && custom_message.after_days_changed?
          custom_message.save

          case custom_message.after_days
          when 0
            # For customers purchaed/booked, so do nothing when this custom custom_message was created
          else
            # custom_message.service.available_customers.find_each do |customer|
            #   ::CustomMessages::Customers::Next.perform_later(
            #     custom_custom_message: custom_message,
            #     receiver: customer,
            #     schedule_right_away: true
            #   )
            # end
          end
        end

        custom_message.save
        custom_message
      end
    end
  end
end
