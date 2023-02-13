# frozen_string_literal: true
# == Schema Information
#
# Table name: broadcasts
#
#  id               :bigint           not null, primary key
#  content          :text             not null
#  query            :jsonb
#  query_type       :string
#  recipients_count :integer          default(0)
#  schedule_at      :datetime
#  sent_at          :datetime
#  state            :integer          default("active")
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  user_id          :bigint           not null
#
# Indexes
#
#  index_broadcasts_on_user_id  (user_id)
#

class Broadcast < ApplicationRecord
  belongs_to :user

  scope :ordered, -> { order(Arel.sql("(CASE WHEN sent_at IS NULL THEN created_at ELSE sent_at END) DESC, id DESC"))  }

  enum state: {
    active: 0,
    draft: 1,
    final: 2
  }

  def broadcast_at
    sent_at || schedule_at || created_at
  end

  def target
    return I18n.t("broadcast.targets.all_customers") if query.blank?

    filter = query["filters"][0]
    product_name =
      case filter["field"]
      when "menu_ids"
        user.menus.find(filter["value"]).name
      when "online_service_ids"
        user.online_services.find(filter["value"]).name
      end

    I18n.t("broadcast.target.specific_product", product_name: product_name)
  end

  def targets
    return I18n.t("broadcast.targets.all_customers") if query.blank?

    query["filters"].map do |filter|
      product_name =
        case filter["field"]
        when "menu_ids"
          user.menus.find(filter["value"]).name
        when "online_service_ids"
          user.online_services.find(filter["value"]).name
        end

      "#{I18n.t("broadcast.targets.fields.#{filter["field"]}")} #{I18n.t("broadcast.targets.conditions.#{filter["condition"]}")} #{product_name}"
    end.join(", ")
  end
end
