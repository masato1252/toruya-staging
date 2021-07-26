# frozen_string_literal: true

# == Schema Information
#
# Table name: business_applications
#
#  id         :bigint           not null, primary key
#  state      :integer          default("pending"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :bigint           not null
#
# Indexes
#
#  index_business_applications_on_user_id  (user_id)
#

class BusinessApplication < ApplicationRecord
  enum state: {
    pending: 0,
    approved: 1,
    rejected: 2,
  }

  belongs_to :user
end
