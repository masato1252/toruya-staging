class Groups::CreateBackupGroup < ActiveInteraction::Base
  BACKUP_GROUP_NAME = "From-Toruya"
  object :user, class: User

  def execute
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    google_group = google_user.create_group(BACKUP_GROUP_NAME)
    ContactGroup.create(user: user, google_uid: user.uid, google_group_id: google_group.id, name: BACKUP_GROUP_NAME)
  end
end
