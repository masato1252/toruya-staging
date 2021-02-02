# frozen_string_literal: true

class RenameOverlapToOverbookingRestrictionInBookingPage < ActiveRecord::Migration[5.2]
  def change
    rename_column :booking_pages, :overlap_restriction, :overbooking_restriction
  end
end
