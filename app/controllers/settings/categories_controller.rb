class Settings::CategoriesController < SettingsController
  before_action :set_category, only: [:edit, :update, :destroy]

  # GET /settings/categories
  # GET /settings/categories.json
  def index
    @settings_categories = super_user.categories
  end

  # GET /settings/categories/1
  # GET /settings/categories/1.json
  def show
  end

  # GET /settings/categories/new
  def new
    @category = super_user.categories.new
  end

  # GET /settings/categories/1/edit
  def edit
  end

  # POST /settings/categories
  # POST /settings/categories.json
  def create
    @category = super_user.categories.new(settings_category_params)

    if @category.save
      redirect_to settings_categories_path, notice: I18n.t("common.create_successfully_message")
    else
      render :new
    end
  end

  # PATCH/PUT /settings/categories/1
  # PATCH/PUT /settings/categories/1.json
  def update
    respond_to do |format|
      if @category.update(settings_category_params)
        format.html { redirect_to settings_categories_path, notice: I18n.t("common.update_successfully_message") }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /settings/categories/1
  # DELETE /settings/categories/1.json
  def destroy
    @category.destroy
    respond_to do |format|
      format.html { redirect_to settings_categories_url, notice: I18n.t("common.delete_successfully_message") }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_category
    @category = super_user.categories.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def settings_category_params
    params.require(:category).permit(:name, :short_name)
  end
end
