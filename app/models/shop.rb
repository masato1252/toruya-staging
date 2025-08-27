# frozen_string_literal: true
# == Schema Information
#
# Table name: shops
#
#  id                     :integer          not null, primary key
#  address                :string           not null
#  address_details        :jsonb
#  deleted_at             :datetime
#  email                  :string
#  holiday_working        :boolean
#  holiday_working_option :string           default("holiday_schedule_without_business_schedule")
#  name                   :string           not null
#  phone_number           :string
#  short_name             :string           not null
#  template_variables     :json
#  website                :string
#  zip_code               :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  user_id                :integer
#
# Indexes
#
#  index_shops_on_user_id_and_deleted_at  (user_id,deleted_at)
#

class Shop < ApplicationRecord
  alias_attribute :company_phone_number, :phone_number
  include ReservationChecking
  include Helpers

  validates :name, presence: true
  validates :short_name, presence: true

  has_one_attached :logo
  has_many :staff_relations, class_name: "ShopStaff", dependent: :destroy
  has_many :shop_staffs, dependent: :destroy
  has_many :staffs, -> { active }, through: :shop_staffs
  has_many :shop_menus, dependent: :destroy
  has_many :menus, -> { active }, through: :shop_menus
  has_many :business_schedules
  has_many :custom_schedules
  has_many :reservations, -> { active }
  has_many :equipments, dependent: :destroy
  has_many :active_equipments, -> { active }, class_name: "Equipment"
  belongs_to :user

  scope :active, -> { where(deleted_at: nil) }

  enum holiday_working_option: {
    business_schedule_overlap_holiday_using_holiday_schedule: "business_schedule_overlap_holiday_using_holiday_schedule",
    holiday_schedule_without_business_schedule: "holiday_schedule_without_business_schedule"
  }

  def staff_users
    staffs.includes(staff_account: :user).map { |staff| staff.staff_account.user.social_user&.current_users }.compact.flatten
  end

  def company_full_address
    if address_details.present?
      Address.new(address_details).display_address
    elsif address.present?
      "〒#{zip_code} #{address}"
    end
  end

  def company_name
    user.profile&.company_name || read_attribute(:name)
  end
  alias_method :name, :company_name
  alias_method :short_name, :company_name

  def logo_url
    ApplicationController.helpers.shop_logo_url(self, "260")
  end

  # XXX: only used for demo
  def message_template_variables(user)
    Templates::ReservationVariables.run!(
      receiver: user,
      shop: self,
      start_time: Time.current,
      end_time: Time.current.advance(hours: 1),
      meeting_url: ApplicationController.helpers.data_by_locale(:official_site_url),
      product_name: I18n.t("common.menu")
    )
  end
end