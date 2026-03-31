# frozen_string_literal: true

class AddVideoUrlToEventContents < ActiveRecord::Migration[7.0]
  def change
    add_column :event_contents, :video_url, :string
  end
end
