# frozen_string_literal: true

# == Schema Information
#
# Table name: contact_group_rankings
#
#  id               :integer          not null, primary key
#  contact_group_id :integer
#  rank_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_contact_group_rankings_on_contact_group_id  (contact_group_id)
#  index_contact_group_rankings_on_rank_id           (rank_id)
#

class ContactGroupRanking < ApplicationRecord
  belongs_to :contact_group
  belongs_to :rank
end
