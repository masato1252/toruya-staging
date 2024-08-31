# frozen_string_literal: true

class SocialUserSerializer
  include JSONAPI::Serializer
  attribute :created_at, :updated_at, :pinned

  attribute :id do |social_user|
    social_user.social_service_user_id
  end

  attribute :shop_customer do |social_user|
    social_user.user&.profile ? ProfileSerializer.new(social_user.user.profile).attributes_hash : nil
  end

  attribute :shop_customers do |social_user|
    social_user.current_users.map do |user|
      ProfileSerializer.new(user.profile).attributes_hash if user.profile
    end.compact
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

  attribute :service_relations_count do |social_user|
    social_user.user ? OnlineServiceCustomerRelation.joins(:online_service).where("online_services.user_id": social_user.user_id).count : 0
  end

  attribute :member_plan_name do |social_user|
    social_user.user&.member_plan_name
  end

  attribute :next_charge_date do |social_user|
    if social_user.user&.subscription&.charge_required && (expired_date = social_user.user&.subscription&.expired_date) && expired_date > Time.current
      I18n.l(social_user.user&.subscription&.expired_date, format: :year_month_date)
    end
  end

  attribute :charge_required do |social_user|
    !!social_user.user&.subscription&.charge_required
  end

  attribute :in_paid_plan do |social_user|
    social_user.user&.subscription&.in_paid_plan
  end

  attribute :sign_up_date do |social_user|
    social_user.user&.subscription&.created_at&.to_date
  end

  attribute :trial_end_date do |social_user|
    social_user.user&.subscription&.trial_expired_date&.to_date
  end

  attribute :where_know_toruya do |social_user|
    social_user.user&.profile&.where_know_toruya
  end

  attribute :what_main_problem do |social_user|
    social_user.user&.profile&.what_main_problem
  end

  attribute :staffs_count do |social_user|
    social_user&.staffs&.size || 0
  end

  attribute :accounts_count do |social_user|
    social_user&.current_users&.size || 0
  end

  attribute :last_visit_time do |social_user|
    if social_user.user
      u = social_user.user
      last_visit_time = [u.customer_latest_activity_at, u.mixpanel_profile_last_set_at].compact.max
      I18n.l(last_visit_time) if last_visit_time
    end
  end

  attribute :personal_schedule_count do |social_user|
    if social_user.user
      CustomSchedule.closed.where(user_id: social_user.current_users.map(&:id)).count
    end
  end
end
