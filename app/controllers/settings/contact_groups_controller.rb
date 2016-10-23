class Settings::ContactGroupsController < SettingsController
  before_action :set_contact_group, only: [:edit, :update, :sync, :connections, :bind, :destroy]

  def index
    @contact_groups = super_user.contact_groups
  end

  def new
    @contact_group = super_user.contact_groups.new
  end

  def create
    outcome = Groups::CreateGroup.run(user: super_user, contact_group_params: contact_group_params.to_h)

    if outcome.valid?
      redirect_to settings_contact_groups_path
    else
      @contact_group = outcome.result
      render :new
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @contact_group.update(contact_group_params)
        format.html { redirect_to settings_contact_groups_path, notice: 'Contact group was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def destroy
    if @contact_group.destroy
      flash[:notice] = "Contact group delete successfully"
    else
      flash[:alert] = "Contact group delete unsuccessfully"
    end

    redirect_to settings_contact_groups_path
  end

  def connections
    @google_groups = Groups::RetrieveGroups.run!(user: super_user)
  end

  def bind
    respond_to do |format|
      if @contact_group.update(google_group_id: params[:google_group_id], google_group_name: params[:google_group_name])
        format.html { redirect_to settings_contact_groups_path, notice: 'Contact Groups was successfully binded.' }
      else
        format.html { render :edit }
      end
    end
  end

  def sync
    outcome = Customers::ImportCustomers.run(user: super_user, contact_group: @contact_group)
    if outcome.valid?
      flash[:notice] = "Synchronization completed"
    end

    redirect_to settings_contact_groups_path
  end

  private

  def contact_group_params
    params.require(:contact_group).permit(:name)
  end

  def set_contact_group
    @contact_group ||= super_user.contact_groups.find(params[:id])
  end
end
