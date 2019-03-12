# == Schema Information
#
# Table name: staffs
#
#  id                       :integer          not null, primary key
#  user_id                  :integer          not null
#  last_name                :string
#  first_name               :string
#  phonetic_last_name       :string
#  phonetic_first_name      :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  deleted_at               :datetime
#  staff_holiday_permission :boolean          default(FALSE), not null
#
# Indexes
#
#  index_staffs_on_user_id                 (user_id)
#  index_staffs_on_user_id_and_deleted_at  (user_id,deleted_at)
#

class Staff < ApplicationRecord
  include NormalizeName
  include ReservationChecking

  belongs_to :user
  has_many :staff_menus, dependent: :destroy
  has_many :menus, -> { active }, through: :staff_menus
  has_many :shop_staffs, dependent: :destroy
  has_many :shops, -> { active }, through: :shop_staffs
  has_many :business_schedules, dependent: :destroy
  has_many :custom_schedules, dependent: :destroy
  has_many :reservation_staffs
  has_many :reservations, through: :reservation_staffs
  has_many :contact_groups, class_name: "StaffContactGroupRelation"
  has_one :staff_account, dependent: :destroy

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  scope :active, -> { undeleted.where.not(first_name: "").joins(:staff_account).merge(StaffAccount.active) }
  scope :active_without_data, -> { undeleted.where(first_name: "").joins(:staff_account).merge(StaffAccount.active) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :undeleted, -> { where(deleted_at: nil) }

  def active?
    !deleted_at && staff_account&.active?
  end

  # no any business schedule exists
  def freelancer?(shop)
    !business_schedules.where(shop: shop).exists?
  end
end
