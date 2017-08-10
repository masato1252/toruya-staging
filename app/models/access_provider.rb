# == Schema Information
#
# Table name: access_providers
#
#  id            :integer          not null, primary key
#  access_token  :string
#  refresh_token :string
#  provider      :string
#  uid           :string
#  user_id       :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  email         :string
#

class AccessProvider < ApplicationRecord
  belongs_to :user
end
