module Users
  class Access < ActiveInteraction::Base
    object :user

    def execute
      now = Time.zone.now
      accessed_at = user.accessed_at

      # update once a day
      if (accessed_at && accessed_at.to_date != now.to_date) || !accessed_at
        user.update_columns(accessed_at: now)

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
