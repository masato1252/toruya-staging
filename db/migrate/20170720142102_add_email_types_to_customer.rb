# frozen_string_literal: true

class AddEmailTypesToCustomer < ActiveRecord::Migration[5.0]
  def change
    add_column :customers, :email_types, :string
  end
end
