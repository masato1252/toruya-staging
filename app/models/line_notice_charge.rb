# frozen_string_literal: true

# == Schema Information
#
# Table name: line_notice_charges
#
#  id                     :bigint           not null, primary key
#  amount                 :decimal(, )      not null
#  amount_currency        :string           default("JPY"), not null
#  charge_date            :date             not null
#  details                :jsonb
#  error_message          :text
#  is_free_trial          :boolean          default(FALSE), not null
#  state                  :integer          default(0), not null
#  stripe_charge_details  :jsonb
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  line_notice_request_id :bigint           not null
#  order_id               :string
#  payment_intent_id      :string
#  reservation_id         :bigint           not null
#  user_id                :bigint           not null
#
# Indexes
#
#  index_line_notice_charges_on_line_notice_request_id  (line_notice_request_id)
#  index_line_notice_charges_on_order_id                (order_id)
#  index_line_notice_charges_on_payment_intent_id       (payment_intent_id)
#  index_line_notice_charges_on_reservation_id          (reservation_id)
#  index_line_notice_charges_on_user_and_free_trial     (user_id,is_free_trial)
#  index_line_notice_charges_on_user_and_state          (user_id,state)
#  index_line_notice_charges_on_user_id                 (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (line_notice_request_id => line_notice_requests.id)
#  fk_rails_...  (reservation_id => reservations.id)
#  fk_rails_...  (user_id => users.id)
#
class LineNoticeCharge < ApplicationRecord
  # Money gem support
  include MoneyRails::ActionViewExtension

  # Relations
  belongs_to :user  # 店舗オーナー
  belongs_to :reservation
  belongs_to :line_notice_request

  # Money columns (amountは実金額で格納、cents変換なし)
  monetize :amount, subunit_to_unit: 1

  # Enums
  enum state: {
    pending: 0,      # 処理待ち
    processing: 1,   # 処理中
    completed: 2,    # 完了
    failed: 3,       # 失敗
    refunded: 4      # 返金済み
  }

  # Validations
  validates :user_id, presence: true
  validates :reservation_id, presence: true
  validates :line_notice_request_id, presence: true
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :amount_currency, presence: true
  validates :charge_date, presence: true
  validates :state, presence: true

  # Callbacks
  before_validation :set_defaults, on: :create
  before_create :generate_order_id

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_user, ->(user_id) { where(user_id: user_id) }
  scope :free_trials, -> { where(is_free_trial: true) }
  scope :paid_charges, -> { where(is_free_trial: false) }
  scope :successful, -> { where(state: [:completed]) }
  scope :chargeable, -> { where(state: [:pending, :failed]) }

  # Constants
  LINE_NOTICE_CHARGE_AMOUNT_JPY = 110  # 円

  # Class methods
  def self.create_free_trial!(user:, reservation:, line_notice_request:)
    create!(
      user: user,
      reservation: reservation,
      line_notice_request: line_notice_request,
      amount: 0,
      amount_currency: user.currency || 'JPY',
      charge_date: Date.current,
      is_free_trial: true,
      state: :completed
    )
  end

  def self.create_paid_charge!(user:, reservation:, line_notice_request:, payment_intent_id: nil, stripe_charge_details: nil)
    create!(
      user: user,
      reservation: reservation,
      line_notice_request: line_notice_request,
      amount: LINE_NOTICE_CHARGE_AMOUNT_JPY,  # 実金額（110円）
      amount_currency: user.currency || 'JPY',
      charge_date: Date.current,
      is_free_trial: false,
      payment_intent_id: payment_intent_id,
      stripe_charge_details: stripe_charge_details,
      state: :completed
    )
  end

  # Instance methods
  def customer
    reservation.customers.first
  end

  def complete!
    update!(state: :completed)
  end

  def fail!(error_msg = nil)
    update!(state: :failed, error_message: error_msg)
  end

  def refund!
    update!(state: :refunded)
  end

  def free?
    is_free_trial
  end

  def paid?
    !is_free_trial
  end

  def successful?
    completed?
  end

  private

  def set_defaults
    self.charge_date ||= Date.current
    self.amount_currency ||= user&.currency || 'JPY'
    
    if is_free_trial
      self.amount = 0
    else
      self.amount ||= LINE_NOTICE_CHARGE_AMOUNT_JPY  # 実金額（110円）
    end
  end

  def generate_order_id
    self.order_id ||= OrderId.generate if defined?(OrderId)
  end
end

