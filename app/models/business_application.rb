# == Schema Information
#
# Table name: business_applications
#
#  id         :bigint(8)        not null, primary key
#  user_id    :bigint(8)        not null
#  state      :integer          default("pending"), not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
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
