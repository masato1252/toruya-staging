# == Schema Information
#
# Table name: lessons
#
#  id            :bigint           not null, primary key
#  content       :json
#  name          :string
#  note          :text
#  solution_type :string
#  chapter_id    :bigint
#
# Indexes
#
#  index_lessons_on_chapter_id  (chapter_id)
#
class Lesson < ApplicationRecord
  belongs_to :chapter
end
