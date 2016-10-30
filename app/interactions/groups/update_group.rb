class Groups::UpdateGroup < ActiveInteraction::Base
  object :contact_group, class: ContactGroup
  hash :params do
    string :name
    array :rank_ids
  end

  def execute
    user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)

    if contact_group.update(params)
      google_user.update_group(contact_group.backup_google_group_id, "#{Groups::CreateGroup::PREFIX}-#{params[:name]}")
    end
  end
end
