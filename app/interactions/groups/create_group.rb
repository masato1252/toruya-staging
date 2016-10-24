class Groups::CreateGroup < ActiveInteraction::Base
  PREFIX = "Toruya"
  object :user, class: User
  hash :contact_group_params do
    string :name
  end

  def execute
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    group = ContactGroup.new(user: user,
                             google_uid: user.uid,
                             name: contact_group_params[:name])
    if group.valid?
      backup_google_group = google_user.create_group("#{PREFIX}-#{contact_group_params[:name]}")

      group.backup_google_group_id = backup_google_group.id
      group.save
    else
      errors.merge!(group.errors)
    end
  end
end
