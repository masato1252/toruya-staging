# frozen_string_literal: true

class SocialUserSerializer
  include JSONAPI::Serializer
  attribute :created_at

  attribute :id do |social_user|
    social_user.social_service_user_id
  end

  attribute :shop_customer do |social_user|
    social_user.user&.profile ? ProfileSerializer.new(social_user.user.profile).attributes_hash : nil
  end

  attribute :channel_id do
    AdminChannel::CHANNEL_NAME
  end

  attribute :name do |social_user|
    social_user.social_user_name
  end

  attribute :unread_message_count do |social_user|
    social_user.social_user_messages.unread.count
  end

  attribute :picture_url do |social_user|
    social_user.social_user_picture_url.presence || "https://via.placeholder.com/60"
  end

  attribute :memo do |social_user|
    social_user.memo_list[0]
  end

  attribute :line_settings_finished do |social_user|
    social_user.user&.social_account&.line_settings_finished?
  end

  attribute :login_api_verified do |social_user|
    social_user.user&.social_account&.login_api_verified?
  end

  attribute :message_api_verified do |social_user|
    social_user.user&.social_account&.message_api_verified?
  end

  attribute :booking_pages_count do |social_user|
    social_user.user&.booking_pages&.count || 0
  end

  attribute :online_services_count do |social_user|
    social_user.user&.online_services&.count || 0
  end

  attribute :sale_pages_count do |social_user|
    social_user.user&.sale_pages&.count || 0
  end

  attribute :customers_count do |social_user|
    social_user.user&.customers&.count || 0
  end

  attribute :reservations_count do |social_user|
    social_user.user&.reservations&.count || 0
  end

  attribute :member_plan_name do |social_user|
    social_user.user&.member_plan_name
  end

  attribute :next_charge_date do |social_user|
    if (expired_date = social_user.user&.subscription&.expired_date) && expired_date > Time.current
      I18n.l(social_user.user&.subscription&.expired_date, format: :year_month_date)
    end
  end

  attribute :in_paid_plan do |social_user|
    social_user.user&.subscription&.in_paid_plan
  end
end
