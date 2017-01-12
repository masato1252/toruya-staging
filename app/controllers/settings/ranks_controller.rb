class Settings::RanksController < SettingsController
  before_action :set_rank, only: [:edit, :update, :destroy]

  # GET /settings/ranks
  # GET /settings/ranks.json
  def index
    @ranks = super_user.ranks
  end

  # GET /settings/ranks/1
  # GET /settings/ranks/1.json
  def show
  end

  # GET /settings/ranks/new
  def new
    @rank = super_user.ranks.new
  end

  # GET /settings/ranks/1/edit
  def edit
  end

  # POST /settings/ranks
  # POST /settings/ranks.json
  def create
    @rank = super_user.ranks.new(rank_params)

    respond_to do |format|
      if @rank.save
        format.html { redirect_to settings_ranks_url, notice: 'Rank was successfully created.' }
      else
        format.html { render :new }
      end
    end
  end

  # PATCH/PUT /settings/ranks/1
  # PATCH/PUT /settings/ranks/1.json
  def update
    respond_to do |format|
      if @rank.update(rank_params)
        format.html { redirect_to settings_ranks_url, notice: 'Rank was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /settings/ranks/1
  # DELETE /settings/ranks/1.json
  def destroy
    @rank.destroy
    respond_to do |format|
      format.html { redirect_to settings_ranks_url, notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_rank
      @rank = super_user.ranks.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def rank_params
      params.require(:rank).permit(:user_id, :name)
    end
end
