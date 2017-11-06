# == Schema Information
#
# Table name: contact_groups
#
#  id                     :integer          not null, primary key
#  user_id                :integer          not null
#  google_uid             :string
#  google_group_name      :string
#  google_group_id        :string
#  backup_google_group_id :string
#  name                   :string           not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#

class ContactGroup < ApplicationRecord
  GOOGLE_GROUP_PREFIX = "Toruya"
  has_many :rankings, class_name: "ContactGroupRanking", dependent: :destroy
  has_many :ranks, through: :rankings
  belongs_to :user

  validates :google_group_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true
  validates :name, uniqueness: { scope: [:user_id] }, presence: true

  before_destroy do
    if google_group_id.present?
      errors.add :base, "Already binding with google group"
      throw(:abort)
    end
  end

  before_validation :assign_default_rankings, on: :create

  scope :connected, -> { where.not(backup_google_group_id: nil) }
  scope :unconnect, -> { where(backup_google_group_id: nil) }

  def google_backup_group_name
    "#{GOOGLE_GROUP_PREFIX}-#{name}"
  end

  private

  def assign_default_rankings
    self.rank_ids = user.rank_ids if rank_ids.blank?
  end
end
