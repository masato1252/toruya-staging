# From google to Toruya
class Groups::RetrieveGroups < ActiveInteraction::Base
  object :user, class: User

  def execute
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    exclude_used_groups(exclude_system_groups(google_user.groups))
  end

  private

  def exclude_system_groups(groups)
    groups.delete_if { |group| group.title.match(/(System Group:|#{Groups::CreateGroup::PREFIX})/) }
  end

  def exclude_used_groups(groups)
    contact_groups = user.contact_groups
    used_group_ids = contact_groups.map{ |contact_group| [contact_group.google_group_id, contact_group.backup_google_group_id] }.flatten.compact
    groups.delete_if { |group| used_group_ids.include?(group.id) }
  end
end
