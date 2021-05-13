# frozen_string_literal: true

# == Schema Information
#
# Table name: broadcasts
#
#  id          :bigint(8)        not null, primary key
#  user_id     :bigint(8)        not null
#  content     :text             not null
#  query       :jsonb
#  schedule_at :datetime
#  sent_at     :datetime
#  state       :integer          default("final")
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_broadcasts_on_user_id  (user_id)
#

class Broadcast < ApplicationRecord
  belongs_to :user

  enum state: {
    final: 0,
    draft: 1
  }
end
