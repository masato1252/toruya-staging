class CustomersController < DashboardController
  # GET /customers
  # GET /customers.json
  def index
    @body_class = "customer"

    @customers = shop.customers.order("updated_at DESC").limit(50)

    @add_reservation_path = if params[:reservation_id].present?
                              edit_shop_reservation_path(shop, id: params[:reservation_id])
                            else
                              new_shop_reservation_path(shop)
                            end
  end

  # POST /customers
  # POST /customers.json
  def save
    if customer_params[:id].present?
      @customer = shop.customers.find(customer_params[:id])
      @customer.update(customer_params)
    else
      @customer = shop.customers.new(customer_params)
      @customer.save
    end
  end

  def delete
    @customer = shop.customers.find(params[:id])
    @customer.destroy

    respond_to do |format|
      format.json { head :no_content }
    end
  end

  def recent
    @customers = shop.customers.order("updated_at DESC").where("updated_at < ?", Time.parse(params[:updated_at])).limit(50)
    render action: :query
  end

  def filter
    @customers = Customers::FilterCustomers.run(
      pattern_number: params[:pattern_number],
      last_customer_id: params[:last_customer_id]
    ).result
    render action: :query
  end

  def search
    @customers = Customers::SearchCustomers.run(
      keyword: params[:keyword],
      last_customer_id: params[:last_customer_id]
    ).result
    render action: :query
  end

  private

  # Never trust parameters from the scary internet, only allow the white list through.
  def customer_params
    params.require(:customer).permit(:id, :last_name, :first_name, :jp_last_name, :jp_first_name, :state, :phone_type, :phone_number, :birthday)
  end
end
