# == Schema Information
#
# Table name: ranks
#
#  id         :integer          not null, primary key
#  user_id    :integer
#  name       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Rank < ApplicationRecord
  belongs_to :user
end
