class AddMeetingUrlToReservations < ActiveRecord::Migration[6.0]
  def change
    add_column :reservations, :meeting_url, :string
  end
end
