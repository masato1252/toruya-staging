
module Notifiers
  module Users
    module Notifications
      class AssigneeAcceptedReservation < Base
        deliver_by_priority [:line, :sms, :email]
        string :assignee_name
        string :booking_time_sentence

        def message
          I18n.t(
            "notifier.notifications.assignee_accepted_reservation.message",
            assignee_name: assignee_name,
            booking_time: booking_time_sentence
          )
        end
      end
    end
  end
end
