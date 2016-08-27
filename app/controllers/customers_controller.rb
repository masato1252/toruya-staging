class CustomersController < DashboardController
  before_action :set_customer, only: [:show, :edit, :update, :destroy]

  # GET /customers
  # GET /customers.json
  def index
    @body_class = "customer"

    @customers = shop.customers.order("updated_at DESC").limit(10)

    @add_reservation_path = if params[:reservation_id].present?
                              edit_shop_reservation_path(shop, id: params[:reservation_id])
                            else
                              new_shop_reservation_path(shop)
                            end
  end

  # GET /customers/1
  # GET /customers/1.json
  def show
  end

  # GET /customers/new
  def new
    @customer = shop.customers.new
  end

  # GET /customers/1/edit
  def edit
  end

  # POST /customers
  # POST /customers.json
  def create
    @customer = shop.customers.new(customer_params)

    respond_to do |format|
      if @customer.save
        format.html { redirect_to shop_customers_path(shop), notice: 'Customer was successfully created.' }
        format.json { render :show, status: :created, location: @customer }
      else
        format.html { render :new }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /customers/1
  # PATCH/PUT /customers/1.json
  def update
    respond_to do |format|
      if @customer.update(customer_params)
        format.html { redirect_to shop_customers_path(shop), notice: 'Customer was successfully updated.' }
        format.json { render :show, status: :ok, location: @customer }
      else
        format.html { render :edit }
        format.json { render json: @customer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /customers/1
  # DELETE /customers/1.json
  def destroy
    @customer.destroy
    respond_to do |format|
      format.html { redirect_to shop_customers_path(shop), notice: 'Customer was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  def filter
    @customers = Customers::FilterCustomers.run(pattern_number: params[:pattern_number]).result
  end

  def search
    @customers = Customers::SearchCustomers.run(keyword: params[:keyword]).result
    render action: :filter
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_customer
    @customer = shop.customers.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def customer_params
    params.require(:customer).permit(:last_name, :first_name, :jp_last_name, :jp_first_name, :state, :phone_type, :phone_number, :birthday)
  end
end
