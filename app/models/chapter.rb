# == Schema Information
#
# Table name: chapters
#
#  id                :bigint           not null, primary key
#  name              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  online_service_id :bigint
#
# Indexes
#
#  index_chapters_on_online_service_id  (online_service_id)
#
class Chapter < ApplicationRecord
  belongs_to :online_service
  has_many :lessons
end
