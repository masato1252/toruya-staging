# frozen_string_literal: true

module Notifiers
  class PendingTasksSummary < Base
    deliver_by :line

    object :period, class: Range

    def message
      pending_reservations_count =
        ReservationCustomer.joins(:reservation).where("reservations.user_id": receiver.id).where("reservation_customers.created_at": period).pending.count
      pending_messages_count = receiver.social_account.social_messages.handleable.unread.where(created_at: period).count
      pending_online_service_count =
        OnlineServiceCustomerRelation.
        joins(:online_service).
        where("online_services.user_id": receiver.id).
        where("online_service_customer_relations.created_at": period).
        pending_payment_state.count

      if pending_reservations_count.positive? || pending_messages_count.positive? || pending_online_service_count.positive?
        content = I18n.t("notifier.pending_tasks_summary.base_message", user_name: receiver.profile.last_name)

        if pending_messages_count.positive?
          content = "#{content}#{I18n.t("notifier.pending_tasks_summary.pending_customer_message", number: pending_messages_count)}"
        end

        if pending_reservations_count.positive?
          content = "#{content}#{I18n.t("notifier.pending_tasks_summary.pending_reservation_message", number: pending_reservations_count)}"
        end

        if pending_online_service_count.positive?
          content = "#{content}#{I18n.t("notifier.pending_tasks_summary.pending_online_service_message", number: pending_online_service_count)}"
        end

        content
      end
    end
  end
end
