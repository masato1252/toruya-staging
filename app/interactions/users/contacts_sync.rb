module Users
  class ContactsSync < ActiveInteraction::Base
    object :user

    def execute
      now = Time.zone.now
      sync_at = user.contacts_sync_at

      # update once a day
      if (sync_at && sync_at.to_date != now.to_date) || !sync_at
        user.update_columns(contacts_sync_at: now)

        import_all_contacts_groups
      end
    end

    private

    def import_all_contacts_groups
      user.contact_groups.connected.find_each do |contact_group|
        CustomersImporterJob.perform_later(contact_group, false)
      end
    end
  end
end
