# frozen_string_literal: true

class DataStaffAccountManagerStaffToEmployee < ActiveRecord::Migration[5.1]
  def change
    StaffAccount.where.not(level: 2).update_all(level: 0)
    StaffAccount.where(level: 2).update_all(level: 1)
  end
end
