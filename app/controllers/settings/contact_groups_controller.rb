class Settings::ContactGroupsController < SettingsController
  before_action :set_contact_group, only: [:edit, :update, :sync, :connections, :bind, :destroy]
  before_action :require_shop_owner

  def index
    @contact_groups = super_user.contact_groups.order("id")
  end

  def new
    @contact_group = super_user.contact_groups.new
  end

  def create
    @contact_group = super_user.contact_groups.new(contact_group_params)

    if @contact_group.save
      redirect_to settings_user_contact_groups_path(super_user), notice: I18n.t("common.create_successfully_message")
    else
      render :new
    end
  end

  def edit
    @ranks = super_user.ranks
  end

  def update
    respond_to do |format|
      outcome = Groups::UpdateGroup.run(contact_group: @contact_group, params: contact_group_params.to_h)

      if outcome.valid?
        format.html { redirect_to settings_user_contact_groups_path(super_user), notice: I18n.t("common.update_successfully_message") }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    @contact_group.destroy
    redirect_to settings_user_contact_groups_path(super_user), notice: I18n.t("common.delete_successfully_message")
  end

  def connections
    @google_groups = Groups::RetrieveGroups.run!(user: super_user)
  end

  def bind
    respond_to do |format|
      outcome = Groups::CreateGroup.run(contact_group: @contact_group,
                                        google_group_id: params[:google_group_id],
                                        google_group_name: params[:google_group_name])
      if outcome.valid?
        format.html { redirect_to settings_user_contact_groups_path(super_user), notice: I18n.t("settings.contact.bind_successfully_message") }
      else
        @contact_group = outcome.result
        format.html { render :edit }
      end
    end
  end

  def sync
    CustomersImporterJob.perform_later(@contact_group)

    redirect_to settings_user_contact_groups_path(super_user), notice: I18n.t("settings.contact.importing_message")
  end

  private

  def contact_group_params
    params.require(:contact_group).permit(:name, rank_ids: [])
  end

  def set_contact_group
    @contact_group ||= super_user.contact_groups.find(params[:id])
  end

  def require_shop_owner
    if super_user != current_user
      redirect_to settings_user_shops_path(super_user), alert: "Only allow shop owner to do this."
    end
  end
end
