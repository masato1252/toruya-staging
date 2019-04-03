class CustomersController < DashboardController
  before_action :contact_group_required

  # GET /customers
  # GET /customers.json
  def index
    authorize! :read, :customers_dashboard
    @body_class = "customer"

    @customers =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC")
      .limit(Customers::Search::PER_PAGE)
    @customer =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:rank, :contact_group).find_by(id: params[:customer_id])

    if shop
      @add_reservation_path = if params[:reservation_id].present?
                                edit_shop_reservation_path(shop, id: params[:reservation_id])
                              else
                                new_shop_reservation_path(shop)
                              end
    end
  end

  def detail
    customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
    authorize! :read, customer

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
    outcome = Customers::Save.run(user: super_user, current_user: current_user, params: params[:customer].permit!.to_h)

    if outcome.valid?
      @customer = outcome.result

      render action: :show
    else
      head :unprocessable_entity
    end
  end

  def delete
    authorize! :edit, Customer

    customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:id])
    outcome = Customers::Delete.run(customer: customer)

    if outcome.valid?
      head :ok
    else
      render json: { error: outcome.errors.full_messages.join(", ") }, status: :unprocessable_entity
    end
  end

  def recent
    @customers =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .includes(:rank, :contact_group, updated_by_user: :profile)
      .order("updated_at DESC")
      .page(params[:page].presence || 1)
      .per(Customers::Search::PER_PAGE)
    render action: :query
  end

  def filter
    @customers = Customers::CharFilter.run(
      super_user: super_user,
      current_user_staff: current_user_staff,
      pattern_number: params[:pattern_number],
      page: params[:page].presence || 1
    ).result
    render action: :query
  end

  def search
    @customers = Customers::Search.run(
      super_user: super_user,
      current_user_staff: current_user_staff,
      keyword: params[:keyword],
      page: params[:page].presence || 1
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
