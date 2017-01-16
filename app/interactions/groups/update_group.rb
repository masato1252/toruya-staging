class Groups::UpdateGroup < ActiveInteraction::Base
  object :contact_group, class: ContactGroup
  hash :params do
    string :name
    # XXX: Don't support custom ranks settings now
    # array :rank_ids, default: nil
  end

  def execute
    user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)

    if contact_group.update(params) && contact_group.backup_google_group_id
      backup_google_group = google_user.update_group(contact_group.backup_google_group_id, "#{ContactGroup::GOOGLE_GROUP_PREFIX}-#{params[:name]}")

      # create new google contact_group_group
      if backup_google_group.try(:id)
        contact_group.backup_google_group_id = backup_google_group.id
        contact_group.save
      else
        # update existing google group
      end
    end
  end
end
