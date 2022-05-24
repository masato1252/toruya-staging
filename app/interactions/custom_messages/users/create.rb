module CustomMessages
  module Users
    class Create < ActiveInteraction::Base
      string :content
      string :scenario
      string :flex_template, default: nil
      integer :after_days
      string :content_type

      validates :after_days, numericality: { greater_than_or_equal_to: 0 }

      def execute
        message = CustomMessage.create(
          scenario: scenario,
          content: content,
          after_days: after_days,
          flex_template: flex_template,
          content_type: content_type
        )

        if message.valid?
          message.save

          case message.after_days
          when 0
            # For user signed up, so do nothing when this custom message was created
          else
            # User.find_each do |user|
            #   ::CustomMessages::Users::Next.perform_later(
            #     custom_message: message,
            #     receiver: user,
            #     schedule_right_away: true
            #   )
            # end
          end
        end

        message
      end
    end
  end
end
