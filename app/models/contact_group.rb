# == Schema Information
#
# Table name: contact_groups
#
#  id              :integer          not null, primary key
#  user_id         :integer          not null
#  google_uid      :string           not null
#  google_group_id :string           not null
#  name            :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class ContactGroup < ApplicationRecord
  validates :google_group_id, uniqueness: { scope: [:user_id, :google_uid] }, presence: true
  validates :name, presence: true
end
