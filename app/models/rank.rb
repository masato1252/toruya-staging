# frozen_string_literal: true

# == Schema Information
#
# Table name: ranks
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string           not null
#  key        :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_ranks_on_user_id  (user_id)
#

class Rank < ApplicationRecord
  VIP_KEY = "vip"
  REGULAR_KEY = "regular"

  belongs_to :user
  validates :name, uniqueness: { scope: [:user_id] }, presence: true
end
