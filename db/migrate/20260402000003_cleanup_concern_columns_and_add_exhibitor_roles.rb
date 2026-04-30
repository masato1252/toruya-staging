# frozen_string_literal: true

# 旧スキーマで participant に存在していた `concern_label` / `concern_category`(単数, string)を撤去し、
# 新しい `concern_categories` (jsonb) と event_contents 側の `exhibitor_roles` (jsonb) を追加する。
#
# 2026-03-31 のリファクタで `create_event_participants` が刷新され、新規環境では
# `concern_label` / `concern_category` カラムは作られない (= remove 対象が存在しない)。
# また再実行時の安全のため、追加カラムも `unless column_exists?` で冪等にする。
class CleanupConcernColumnsAndAddExhibitorRoles < ActiveRecord::Migration[7.0]
  def up
    safety_assured do
      if column_exists?(:event_participants, :concern_label)
        remove_column :event_participants, :concern_label
      end
      if column_exists?(:event_participants, :concern_category)
        remove_column :event_participants, :concern_category
      end
    end

    unless column_exists?(:event_participants, :concern_categories)
      add_column :event_participants, :concern_categories, :jsonb, null: false, default: []
    end

    unless column_exists?(:event_contents, :exhibitor_roles)
      add_column :event_contents, :exhibitor_roles, :jsonb, null: false, default: []
    end
  end

  def down
    if column_exists?(:event_contents, :exhibitor_roles)
      remove_column :event_contents, :exhibitor_roles
    end
    if column_exists?(:event_participants, :concern_categories)
      remove_column :event_participants, :concern_categories
    end
    # 旧 `concern_label` / `concern_category` (string) は元の値もスキーマも復元できないため
    # ロールバック時に再作成しない。必要なら手動で再追加する。
  end
end
