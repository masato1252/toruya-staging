# From google to Toruya
class Groups::RetrieveGroups < ActiveInteraction::Base
  object :user, class: User

  def execute
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    exclude_system_groups(google_user.groups)
  end

  private

  def exclude_system_groups(groups)
    groups.delete_if { |group| group.title.match(/(System Group:|\A#{Groups::CreateBackupGroup::BACKUP_GROUP_NAME}\Z)/) }
  end
end
