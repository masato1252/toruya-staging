# frozen_string_literal: true

require "slack_client"

class HiJob < ApplicationJob
  queue_as :message_queue

  # Support object was because sometime, we don't want to the status of object right away,
  # for example: after customer paid the bill, otherwise, it usually always be pending status.
  def perform(hiable_object_or_hi_message, channel_name = nil)
    channel = channel_name || "sayhi"
    text = hiable_object_or_hi_message.is_a?(String) ? hiable_object_or_hi_message : hiable_object_or_hi_message.hi_message

    if hiable_object_or_hi_message.is_a?(SocialUserMessage)
      today_user_last_message = SocialUserMessage.where(social_user: hiable_object_or_hi_message.social_user, message_type: "user").where("created_at": Time.current.beginning_of_day..hiable_object_or_hi_message.created_at).where.not(id: hiable_object_or_hi_message.id).last
      # message is not under a thread
      ##<Slack::Messages::Message channel="C0201K35WMC" message=#<Slack::Messages::Message bot_id="BEUSDMU3Z" subtype="bot_message" text=":thought_balloon: `user_id: 1, iamilake` <https://manager.toruya.com/admin/chats?social_service_user_id=Ud5a6c48f7716e81f8086d1a9467fea42|chat link>\n      Reply me" ts="1670519197.432129" type="message"> ok=true ts="1670519197.432129">
      # message already under a thread
      # <Slack::Messages::Message channel="C0201K35WMC" message=#<Slack::Messages::Message bot_id="BEUSDMU3Z" subtype="bot_message" text=":thought_balloon: `user_id: 1, iamilake` <https://manager.toruya.com/admin/chats?social_service_user_id=Ud5a6c48f7716e81f8086d1a9467fea42|chat link>\n      Reply me" thread_ts="1670517710.051829" ts="1670519403.647609" type="message"> ok=true ts="1670519403.647609">
      #
      if text.match?(/解約申請/)
        response = SlackClient.send(channel: "churn_users", text: text, thread_ts: today_user_last_message&.slack_message_id)
      else
        response = SlackClient.send(channel: channel, text: text, thread_ts: today_user_last_message&.slack_message_id)
      end

      if response.message.nil?
        Rollbar.error("HiJob: slack message is nil", response: response)
      end

      hiable_object_or_hi_message.update_columns(slack_message_id: today_user_last_message&.slack_message_id || response.message&.thread_ts || response.message&.ts)
    else
      SlackClient.send(channel: channel, text: text)
    end
  end
end
