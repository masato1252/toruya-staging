# == Schema Information
#
# Table name: lessons
#
#  id            :bigint           not null, primary key
#  content_url   :string
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
  include ContentHelper

  belongs_to :chapter
end
