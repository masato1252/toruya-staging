# frozen_string_literal: true

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
#  introduction             :text
#
# Indexes
#
#  index_staffs_on_user_id_and_deleted_at  (user_id,deleted_at)
#

class Staff < ApplicationRecord
  include NormalizeName
  include ReservationChecking

  has_one_attached :picture
  belongs_to :user
  has_many :staff_menus, dependent: :destroy
  has_many :menus, -> { active }, through: :staff_menus
  has_many :shop_relations, class_name: "ShopStaff", dependent: :destroy
  has_many :shop_staffs, dependent: :destroy
  has_many :shops, -> { active }, through: :shop_staffs
  has_many :business_schedules, dependent: :destroy
  has_many :custom_schedules, dependent: :destroy
  has_many :reservation_staffs
  has_many :reservations, through: :reservation_staffs
  has_many :contact_group_relations, class_name: "StaffContactGroupRelation", dependent: :destroy
  has_many :contact_groups, through: :contact_group_relations
  has_one :staff_account, dependent: :destroy

  accepts_nested_attributes_for :staff_menus, allow_destroy: true

  scope :active, -> { undeleted.where.not(first_name: "").joins(:staff_account).merge(StaffAccount.active.visible) }
  scope :active_without_data, -> { undeleted.where(first_name: "").joins(:staff_account).merge(StaffAccount.active.visible) }
  scope :deleted, -> { where.not(deleted_at: nil) }
  scope :undeleted, -> { where(deleted_at: nil) }
  scope :visible, -> { joins(:staff_account).merge(StaffAccount.visible) }

  delegate :phone_number, :email, :level, to: :staff_account, allow_nil: true

  def active?
    !deleted_at && staff_account&.active?
  end

  def state
    if active?
      "active"
    elsif deleted_at?
      "deleted"
    else
      "pending"
    end
  end

  def display_name
    name.presence || staff_account.phone_number.presence || staff_account.email.presence || "スタッフ #{id}"
  end

  # no any business schedule exists
  def freelancer?(shop)
    !business_schedules.where(shop: shop).exists?
  end

  def readable_contact_groups
    @readable_contact_groups ||= (staff_account.owner? || staff_account.admin?) ? user.contact_groups : contact_groups
  end

  def readable_contact_group_ids
    @readable_contact_group_ids ||= (staff_account.owner? || staff_account.admin?) ? user.contact_group_ids.push(nil) : contact_group_relations.pluck(:contact_group_id)
  end

  def related_staffs
    staff_account.user&.social_user&.staffs
  end
end
