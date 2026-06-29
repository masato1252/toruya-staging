# frozen_string_literal: true

class DocLineUser < ApplicationRecord
  has_many :doc_downloads, dependent: :destroy

  validates :line_user_id, presence: true, uniqueness: true

  def display_label
    display_name.presence || line_user_id
  end
end
