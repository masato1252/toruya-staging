# frozen_string_literal: true

require "message_encryptor"

module SocialAccounts
  class Update < ActiveInteraction::Base
    INVALID_TOKEN_REGEXP = /[:]/

    object :user
    string :update_attribute

    hash :attrs, default: nil, strip: false do
      string :channel_id, default: nil
      string :channel_token, default: nil
      string :channel_secret, default: nil
      string :label, default: nil
      string :basic_id, default: nil
      string :login_channel_id, default: nil
      string :login_channel_secret, default: nil
    end

    validate :validate_full_width_characters
    validate :validate_raw_settings

    def execute
      begin
        SocialAccount.transaction do
          account = user.social_accounts.first || user.social_accounts.new

          if %w[channel_id login_channel_id].include?(update_attribute)
            old_value = account.send(update_attribute)
            new_value = attrs[update_attribute]
            if old_value.present? && new_value.present? && old_value != new_value
              stale_customer_ids = account.social_customers.pluck(:id)
              if stale_customer_ids.any?
                SocialMessage.where(social_customer_id: stale_customer_ids)
                             .update_all(social_customer_id: nil)
                account.social_customers.delete_all
              end
            end
          end

          case update_attribute
          when "channel_id", "label", "basic_id", "login_channel_id"
            account.update(attrs.slice(update_attribute))
          when "channel_token"
            account.update(channel_token: MessageEncryptor.encrypt(attrs[:channel_token]&.strip))
          when "channel_secret"
            account.update(channel_secret: MessageEncryptor.encrypt(attrs[:channel_secret]&.strip))
          when "login_channel_secret"
            account.update(login_channel_secret: MessageEncryptor.encrypt(attrs[:login_channel_secret]&.strip))
          end

          if account.line_settings_verified?
            SocialAccounts::RichMenus::CustomerReservations.perform_later(social_account: account)
          end

          if account.line_settings_finished?
            Notifiers::Users::LineSettings::FinishedMessage.perform_later(receiver: user.social_user)
            Notifiers::Users::LineSettings::FinishedFlex.perform_later(receiver: user.social_user)
            Notifiers::Users::LineSettings::FinishedVideo.perform_later(receiver: user.social_user)
          end

          account
        end
      rescue ActiveRecord::RecordNotUnique
        retry
      end
    end

    private

    def validate_full_width_characters
      errors.add(:attrs, :has_full_width_characters) if attrs[:channel_id].present? && attrs[:channel_id].multibyte?
      errors.add(:attrs, :has_full_width_characters) if attrs[:channel_token].present? && attrs[:channel_token].multibyte?
      errors.add(:attrs, :has_full_width_characters) if attrs[:channel_secret].present? && attrs[:channel_secret].multibyte?
      errors.add(:attrs, :has_full_width_characters) if attrs[:basic_id].present? && attrs[:basic_id].multibyte?
      errors.add(:attrs, :has_full_width_characters) if attrs[:login_channel_id].present? && attrs[:login_channel_id].multibyte?
      errors.add(:attrs, :has_full_width_characters) if attrs[:login_channel_secret].present? && attrs[:login_channel_secret].multibyte?
    end

    def validate_raw_settings
      if attrs[:channel_token]&.match?(INVALID_TOKEN_REGEXP)
        errors.add(:attrs, :invalid_settings)
      end

      if attrs[:channel_secret]&.match?(INVALID_TOKEN_REGEXP)
        errors.add(:attrs, :invalid_settings)
      end

      if attrs[:login_channel_secret]&.match?(INVALID_TOKEN_REGEXP)
        errors.add(:attrs, :invalid_settings)
      end
    end
  end
end
