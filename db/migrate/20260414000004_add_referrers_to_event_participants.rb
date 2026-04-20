class AddReferrersToEventParticipants < ActiveRecord::Migration[7.0]
  def change
    add_reference :event_participants, :referrer_shop,
                  foreign_key: { to_table: :shops }, null: true
    add_reference :event_participants, :referrer_event_line_user,
                  foreign_key: { to_table: :event_line_users }, null: true
  end
end
