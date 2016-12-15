class CustomersController < DashboardController
  # GET /customers
  # GET /customers.json
  def index
    @body_class = "customer"

    @customers = super_user.customers.includes(:contact_group).order("updated_at DESC").limit(50)
    @customer = super_user.customers.includes(:contact_group).find_by(id: params[:customer_id])

    @add_reservation_path = if params[:reservation_id].present?
                              edit_shop_reservation_path(shop, id: params[:reservation_id])
                            else
                              new_shop_reservation_path(shop)
                            end
    @contact_groups = super_user.contact_groups
    @ranks = super_user.ranks
  end

  def detail
    customer = super_user.customers.find(params[:id])
    @customer = if customer.google_contact_id
                  customer.build_by_google_contact(Customers::RetrieveGoogleContact.run!(customer: customer))
                else
                  customer
                end
    render action: :show
  end

  # POST /customers
  # POST /customers.json
  def save
    outcome = Customers::Save.run(user: super_user, params: params[:customer].permit!.to_h)
    @customer = outcome.result

    render action: :show
  end

  def delete
    @customer = super_user.customers.find(params[:id])
    @customer.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def recent
    @customers = super_user.customers.order("updated_at DESC").where("updated_at < ?", Time.parse(params[:updated_at])).limit(50)
    render action: :query
  end

  def filter
    @customers = Customers::Filter.run(
      super_user: super_user,
      pattern_number: params[:pattern_number],
      last_customer_id: params[:last_customer_id]
    ).result
    render action: :query
  end

  def search
    @customers = Customers::Search.run(
      super_user: super_user,
      keyword: params[:keyword],
      last_customer_id: params[:last_customer_id]
    ).result
    render action: :query
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def customer_params
    params.require(:customer).permit(
      :id, :contact_group_id, :rank_id, :last_name, :first_name, :phonetic_last_name, :phonetic_first_name,
      :primary_phone, :primary_email,
      :phone_type, :phone_number, :birthday,
      address: [:postcode1, :postcode2, :region, :city, :street1, :street2],
      phone_numbers: []
    )
  end
end
