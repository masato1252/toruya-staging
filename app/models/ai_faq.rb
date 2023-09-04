# == Schema Information
#
# Table name: ai_faqs
#
#  id         :bigint           not null, primary key
#  answer     :text
#  question   :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  user_id    :string
#
# Indexes
#
#  index_ai_faqs_on_user_id  (user_id)
#
class AiFaq < ApplicationRecord
end
