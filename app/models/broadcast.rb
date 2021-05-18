# frozen_string_literal: true
# == Schema Information
#
# Table name: broadcasts
#
#  id               :bigint(8)        not null, primary key
#  user_id          :bigint(8)        not null
#  content          :text             not null
#  query            :jsonb
#  schedule_at      :datetime
#  sent_at          :datetime
#  state            :integer          default("final")
#  recipients_count :integer          default(0)
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_broadcasts_on_user_id  (user_id)
#

class Broadcast < ApplicationRecord
  belongs_to :user

  enum state: {
    final: 0,
    draft: 1
  }

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
