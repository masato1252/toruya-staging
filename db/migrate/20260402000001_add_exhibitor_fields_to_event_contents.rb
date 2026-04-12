# frozen_string_literal: true

class AddExhibitorFieldsToEventContents < ActiveRecord::Migration[7.0]
  def change
    add_column :event_contents, :exhibitor_company_name, :string
    add_column :event_contents, :exhibitor_description, :text
  end
end
