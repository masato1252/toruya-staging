# frozen_string_literal: true

class EventLineMessageBroadcastJob < ApplicationJob
  queue_as :message_queue

  def perform(broadcast)
    broadcast.reload
    return unless broadcast.status_pending?
    return if broadcast.scheduled_at.future?

    broadcast.update!(status: :delivering)

    target_event_line_users(broadcast).find_each do |event_line_user|
      delivery = broadcast.event_line_message_broadcast_deliveries.find_or_initialize_by(event_line_user: event_line_user)
      next if delivery.sent_at.present?

      begin
        send_line_message(event_line_user.line_user_id, broadcast.message)
        delivery.assign_attributes(sent_at: Time.current, error_message: nil)
      rescue StandardError => e
        delivery.error_message = "#{e.class}: #{e.message}".truncate(1000)
        Rollbar.error(e, "Failed to send event LINE broadcast", broadcast_id: broadcast.id, event_line_user_id: event_line_user.id)
      ensure
        delivery.save!
      end
    end

    deliveries = broadcast.event_line_message_broadcast_deliveries
    broadcast.update!(
      status: :delivered,
      sent_at: Time.current,
      delivered_count: deliveries.where.not(sent_at: nil).count,
      failed_count: deliveries.where(sent_at: nil).where.not(error_message: [nil, ""]).count
    )
  rescue StandardError => e
    broadcast.update(status: :pending) if defined?(broadcast) && broadcast&.status_delivering?
    Rollbar.error(e, "Failed to process event LINE broadcast", broadcast_id: broadcast&.id)
    raise
  end

  private

  def target_event_line_users(broadcast)
    EventLineUser
      .joins(:event_participants)
      .where(event_participants: { event_id: broadcast.event_id })
      .where.not(event_participants: { event_line_user_id: nil })
      .distinct
  end

  def send_line_message(line_user_id, message)
    UserBotSocialAccount.client.push_message(line_user_id, { type: "text", text: message })
  end
end
