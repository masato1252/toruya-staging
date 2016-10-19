class Settings::ContactGroupsController < SettingsController
  before_action :set_contact_group, only: [:edit, :update, :sync]

  def new
    @contact_group = super_user.contact_groups.new(google_group_id: params[:google_group_id],
                                                   name: params[:name],
                                                   google_uid: current_user.uid)
  end

  def create
    @contact_group = super_user.contact_groups.new(contact_group_params)

    if @contact_group.save
      redirect_to settings_synchronizations_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    respond_to do |format|
      if @contact_group.update(contact_group_params)
        format.html { redirect_to settings_synchronizations_path, notice: 'Contact group was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  def sync
    outcome = Customers::ImportCustomers.run(user: super_user, google_group_id: @contact_group.google_group_id)
    if outcome.valid?
      flash[:notice] = "Synchronization completed"
    end

    redirect_to settings_synchronizations_path
  end

  private

  def contact_group_params
    params.require(:contact_group).permit(:name, :google_uid, :google_group_id)
  end

  def set_contact_group
    @contact_group ||= super_user.contact_groups.find(params[:id])
  end
end
