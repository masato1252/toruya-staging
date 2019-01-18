class Groups::CreateGroup < ActiveInteraction::Base
  object :contact_group, class: ContactGroup
  string :google_group_id, default: nil
  string :google_group_name, default: nil

  def execute
    user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)

    backup_google_group = google_user.create_group(contact_group.google_backup_group_name)

    contact_group.google_group_name = google_group_name
    contact_group.google_group_id = google_group_id
    contact_group.google_uid = user.uid
    contact_group.backup_google_group_id = backup_google_group.id

    if contact_group.save
      CustomersImporterJob.perform_later(contact_group)
    end

    contact_group
  end
end
