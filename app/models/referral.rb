# frozen_string_literal: true

# == Schema Information
#
# Table name: referrals
#
#  id          :bigint           not null, primary key
#  state       :integer          default("pending"), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  referee_id  :integer          not null
#  referrer_id :integer          not null
#
# Indexes
#
#  index_referrals_on_referrer_id  (referrer_id) UNIQUE
#

# active set to nil when child account become business member
class Referral < ApplicationRecord
  belongs_to :referrer, class_name: "User"
  belongs_to :referee, class_name: "User"

  enum state: {
    pending: 0, # Sign up, free plan
    active: 1, # subscribed paid plan
    referrer_canceled: 2, # ever subscribed others plan whatever a free/regular/business
  }

  scope :enabled, -> { where(state: %i(pending active)) }
end
