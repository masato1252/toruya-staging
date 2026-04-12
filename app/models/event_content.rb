# frozen_string_literal: true

# == Schema Information
#
# Table name: event_contents
#
#  id                     :bigint           not null, primary key
#  capacity               :integer
#  content_type           :integer          default("seminar"), not null
#  deleted_at             :datetime
#  description            :text
#  direct_download_url    :string
#  end_at                 :datetime
#  exhibitor_company_name :string
#  exhibitor_description  :text
#  exhibitor_roles        :jsonb            not null
#  introduction           :text
#  monitor_enabled        :boolean          default(FALSE), not null
#  monitor_form_url       :string
#  monitor_limit          :integer
#  monitor_name           :string
#  monitor_price          :integer
#  position               :integer          default(0), not null
#  post_ad_video_url      :string
#  pre_ad_video_url       :string
#  start_at               :datetime
#  title                  :string           not null
#  upsell_booking_enabled :boolean          default(FALSE), not null
#  video_url              :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  event_id               :bigint           not null
#  online_service_id      :bigint
#  shop_id                :bigint
#  upsell_booking_page_id :bigint
#
# Indexes
#
#  index_event_contents_on_deleted_at              (deleted_at)
#  index_event_contents_on_event_id                (event_id)
#  index_event_contents_on_event_id_and_position   (event_id,position)
#  index_event_contents_on_online_service_id       (online_service_id)
#  index_event_contents_on_shop_id                 (shop_id)
#  index_event_contents_on_upsell_booking_page_id  (upsell_booking_page_id)
#
# Foreign Keys
#
#  fk_rails_...  (event_id => events.id)
#  fk_rails_...  (online_service_id => online_services.id)
#  fk_rails_...  (shop_id => shops.id)
#  fk_rails_...  (upsell_booking_page_id => booking_pages.id)
#
class EventContent < ApplicationRecord
  belongs_to :event
  belongs_to :shop, optional: true
  belongs_to :online_service, optional: true
  belongs_to :upsell_booking_page, class_name: "BookingPage", optional: true

  has_many :event_content_images, -> { order(:position) }, dependent: :destroy
  has_many :event_content_speakers, -> { order(:position) }, dependent: :destroy
  has_many :event_content_usages, dependent: :destroy
  has_many :event_upsell_consultations, dependent: :destroy
  has_many :event_monitor_applications, dependent: :destroy
  has_many :event_activity_logs, dependent: :destroy
  has_many :event_stamp_entries, dependent: :destroy

  has_one_attached :thumbnail
  has_one_attached :exhibitor_logo

  enum content_type: { seminar: 0, booth: 1 }, _suffix: true

  validates :title, presence: true
  validates :exhibitor_company_name, presence: true, if: :booth_content_type?

  scope :undeleted, -> { where(deleted_at: nil) }
  scope :active, -> { where(deleted_at: nil) }

  def soft_delete!
    update!(deleted_at: Time.current)
  end

  def started?
    start_at.present? && start_at <= Time.current
  end

  def ended?
    end_at.present? && end_at < Time.current
  end

  def usage_count
    event_content_usages.count
  end

  def capacity_full?
    capacity.present? && usage_count >= capacity
  end

  def consultation_count
    event_upsell_consultations.where(status: :confirmed).count
  end

  def consultation_full?
    return false unless upsell_booking_enabled?
    # capacity of booking page is checked separately via booking_page
    false
  end
end
