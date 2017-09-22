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

class ReservationQueryFilter < QueryFilter
end
