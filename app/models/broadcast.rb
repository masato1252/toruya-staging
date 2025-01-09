# frozen_string_literal: true
# == Schema Information
#
# Table name: broadcasts
#
#  id                           :bigint           not null, primary key
#  content                      :text             not null
#  customers_permission_warning :boolean          default(FALSE)
#  query                        :jsonb
#  query_type                   :string
#  recipients_count             :integer          default(0)
#  schedule_at                  :datetime
#  sent_at                      :datetime
#  state                        :integer          default("active")
#  created_at                   :datetime         not null
#  updated_at                   :datetime         not null
#  user_id                      :bigint           not null
#
# Indexes
#
#  index_broadcasts_on_user_id  (user_id)
#

class Broadcast < ApplicationRecord
  belongs_to :user
  TYPES = ["menu", "online_service", "online_service_for_active_customers", "vip_customers", "reservation_customers", "customers_with_tags", "customers_with_birthday", "active_customers"]
  NORMAL_TYPES = TYPES - ["reservation_customers"]

  scope :ordered, -> { order(Arel.sql("(CASE WHEN sent_at IS NULL THEN created_at ELSE sent_at END) DESC, id DESC"))  }
  scope :normal, -> { where(query_type: NORMAL_TYPES) }
  validates :query_type, inclusion: { in: TYPES }

  enum state: {
    active: 0,
    draft: 1,
    final: 2
  }

  enum query_type: {
    menu: "menu",
    online_service: "online_service",
    online_service_for_active_customers: "online_service_for_active_customers",
    vip_customers: "vip_customers",
    reservation_staffs: "reservation_staffs",
    reservation_customers: "reservation_customers",
    customers_with_tags: "customers_with_tags",
    customers_with_birthday: "customers_with_birthday",
    active_customers: "active_customers"
  }

  def broadcast_at
    sent_at || schedule_at || created_at
  end

  def target
    return I18n.t("broadcast.targets.all_customers") if query.blank?
    return I18n.t("broadcast.targets.vip_customers") if vip_customers?
    return I18n.t("broadcast.targets.active_customers") if active_customers?
    return I18n.t("broadcast.targets.all_customers") if query["filters"].blank?

    filter = query["filters"][0]
    product_name =
      case filter["field"]
      when "menu_ids"
        user.menus.find(id: filter["value"])&.name
      when "online_service_ids"
        user.online_services.find(id: filter["value"])&.name
      when "tags"
        filter["value"]
      when "birthday"
        if filter["condition"] == "age_range"
          age_start = filter["value"][0].to_i
          age_end = filter["value"][1].to_i
          I18n.t("user_bot.dashboards.broadcast_creation.age_range_desc", age_start: age_start, age_end: age_end)
        else
          I18n.t("user_bot.dashboards.broadcast_creation.birthday_month_desc", month: filter["value"])
        end
      end

    I18n.t("broadcast.target.specific_product", product_name: product_name)
  end

  def targets
    return [I18n.t("broadcast.targets.all_customers")] if query.blank?
    return [I18n.t("broadcast.targets.vip_customers")] if vip_customers?
    return [I18n.t("broadcast.targets.active_customers")] if active_customers?
    return [I18n.t("broadcast.targets.all_customers")] if query["filters"].blank?

    query["filters"].map do |filter|
      case filter["field"]
      when "menu_ids"
        user.menus.find_by(id: filter["value"])&.name
      when "online_service_ids"
        user.online_services.find_by(id: filter["value"]).name
      when "tags"
        filter["value"]
      when "birthday"
        if filter["condition"] == "age_range"
          age_start = filter["value"][0].to_i
          age_end = filter["value"][1].to_i
          I18n.t("user_bot.dashboards.broadcast_creation.age_range_desc", age_start: age_start, age_end: age_end)
        else
          I18n.t("user_bot.dashboards.broadcast_creation.birthday_month_desc", month: filter["value"])
        end
      end
    end.compact
  end

  def target_ids
    return [] if query["filters"].blank?

    query["filters"].map do |filter|
      filter["value"]
    end
  end
end
