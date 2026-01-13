# frozen_string_literal: true

class CreateLineNoticeRequests < ActiveRecord::Migration[7.0]
  def change
    create_table :line_notice_requests do |t|
      t.references :reservation, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true  # 店舗オーナーID
      t.integer :status, default: 0, null: false  # 0: pending, 1: approved, 2: rejected, 3: expired
      t.datetime :approved_at
      t.datetime :rejected_at
      t.datetime :expired_at
      t.text :rejection_reason
      t.timestamps
    end

    # 複合インデックス（同一予約への重複リクエスト防止）
    add_index :line_notice_requests, [:reservation_id, :status], 
      name: 'index_line_notice_requests_on_reservation_and_status'
  end
end
