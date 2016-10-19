class Settings::SynchronizationsController < SettingsController
  def index
    @google_groups = Groups::RetrieveGroups.run!(user: super_user)
    @contact_groups = super_user.contact_groups
  end
end
