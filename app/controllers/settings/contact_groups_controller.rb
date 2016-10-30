class Settings::ContactGroupsController < SettingsController
  before_action :set_contact_group, only: [:edit, :update, :sync, :connections, :bind, :destroy]
  def index
    @contact_groups = super_user.contact_groups
  end

  def new
    @contact_group = super_user.contact_groups.new
    @ranks = super_user.ranks
    @ranking_ids = []
  end

  def create
    @contact_group = super_user.contact_groups.new(contact_group_params)

    if @contact_group.save
      redirect_to settings_contact_groups_path
    else
      render :new
    end
  end

  def edit
    @ranks = super_user.ranks
    @ranking_ids = @contact_group.rankings.pluck(:rank_id)
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
      outcome = Groups::CreateGroup.run(contact_group: @contact_group,
                                        google_group_id: params[:google_group_id],
                                        google_group_name: params[:google_group_name])
      if outcome.valid?
        format.html { redirect_to settings_contact_groups_path, notice: 'Contact Groups was successfully binded.' }
      else
        @contact_group = outcome.result
        format.html { render :edit }
      end
    end
  end

  def sync
    CustomersImporterJob.perform_later(@contact_group)

    flash[:notice] = "We are importing your customers, would notify you when the process finished"
    redirect_to settings_contact_groups_path
  end

  private

  def contact_group_params
    params.require(:contact_group).permit(:name, rank_ids: [])
  end

  def set_contact_group
    @contact_group ||= super_user.contact_groups.find(params[:id])
  end
end
