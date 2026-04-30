# frozen_string_literal: true

# 旧スキーマの event_content_usages / event_upsell_consultations / event_monitor_applications に
# 残っている `social_customer_id` (NOT NULL) を null 許容化する。
#
# 2026-03-31 のリファクタ以降の新規環境では、これら 3 テーブルは
# `event_line_user_id` ベースで作成され `social_customer_id` カラムが存在しない。
# よって fresh DB ではこのマイグレーションは no-op となるよう `column_exists?` でガードする。
class AllowNullSocialCustomerIdOnEventContentActivities < ActiveRecord::Migration[7.0]
  TARGET_TABLES = %i[event_content_usages event_upsell_consultations event_monitor_applications].freeze

  def change
    TARGET_TABLES.each do |table|
      next unless column_exists?(table, :social_customer_id)

      change_column_null table, :social_customer_id, true
    end
  end
end
