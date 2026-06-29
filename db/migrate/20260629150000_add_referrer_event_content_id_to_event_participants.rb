# frozen_string_literal: true

class AddReferrerEventContentIdToEventParticipants < ActiveRecord::Migration[7.0]
  def change
    add_reference :event_participants, :referrer_event_content,
                  foreign_key: { to_table: :event_contents }, null: true, index: true
  end
end
