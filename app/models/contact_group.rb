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
  belongs_to :user

  validates :google_group_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true, allow_nil: true
  validates :name, uniqueness: { scope: [:user_id] }, presence: true

  before_destroy do
    if google_group_id.present?
      errors.add :base, "Already binding with google group"
      throw(:abort)
    end
  end
end
