# frozen_string_literal: true

class CreateLineNoticeCharges < ActiveRecord::Migration[7.0]
  def change
    create_table :line_notice_charges do |t|
      t.references :user, null: false, foreign_key: true, index: true  # 店舗オーナーID
      t.references :reservation, null: false, foreign_key: true, index: true
      t.references :line_notice_request, null: false, foreign_key: true, index: true
      t.decimal :amount, null: false  # 実金額（110円なら110）
      t.string :amount_currency, null: false, default: 'JPY'
      t.integer :state, default: 0, null: false  # 0: pending, 1: processing, 2: completed, 3: failed, 4: refunded
      t.date :charge_date, null: false
      t.boolean :is_free_trial, default: false, null: false
      t.jsonb :stripe_charge_details  # Stripe決済の詳細情報
      t.jsonb :details  # その他の詳細情報
      t.string :order_id
      t.string :payment_intent_id
      t.text :error_message
      t.timestamps
    end

    # インデックス
    add_index :line_notice_charges, :order_id, name: 'index_line_notice_charges_on_order_id'
    add_index :line_notice_charges, :payment_intent_id, name: 'index_line_notice_charges_on_payment_intent_id'
    
    # 複合インデックス
    add_index :line_notice_charges, [:user_id, :state], 
      name: 'index_line_notice_charges_on_user_and_state'
    add_index :line_notice_charges, [:user_id, :is_free_trial], 
      name: 'index_line_notice_charges_on_user_and_free_trial'
  end
end
