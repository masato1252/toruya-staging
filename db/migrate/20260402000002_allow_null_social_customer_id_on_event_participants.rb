# frozen_string_literal: true

# 旧スキーマ(`event_participants.social_customer_id` が NOT NULL)を維持している環境向けの
# null 許容化マイグレーション。
#
# 2026-03-31 のリファクタ以降、新規環境では `create_event_participants` が
# `event_line_user_id` ベースの構成になり `social_customer_id` カラムは作られない。
# よって toruya-production などの fresh DB では本マイグレーションは「何もする対象がない」状態となるため、
# `column_exists?` ガードで no-op にして失敗を防ぐ。
class AllowNullSocialCustomerIdOnEventParticipants < ActiveRecord::Migration[7.0]
  def change
    return unless column_exists?(:event_participants, :social_customer_id)

    change_column_null :event_participants, :social_customer_id, true
  end
end
