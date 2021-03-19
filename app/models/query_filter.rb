# frozen_string_literal: true

# == Schema Information
#
# Table name: query_filters
#
#  id         :integer          not null, primary key
#  user_id    :integer          not null
#  name       :string           not null
#  type       :string           not null
#  query      :jsonb
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_query_filters_on_user_id  (user_id)
#

class QueryFilter < ApplicationRecord
  validates :name, uniqueness: { scope: [:user_id, :type] }
end
