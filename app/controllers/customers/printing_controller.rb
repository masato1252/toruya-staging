class Customers::PrintingController < DashboardController

  def new
    @customer = super_user.customers.find(params[:customer_id]).with_google_contact
    @page_size = params[:page_size]

    options = {
      :pdf => "customer",
      title: @customer.name,
      show_as_html: params.key?('debug')
    }.merge!(Customers::PrintingConfig.run!(page_size: @page_size))

    render options
  end

  def index
    filter_outcome = super_user.filter_outcomes.create

    CustomersPrintingJob.perform_later(super_user, filter_outcome, params[:page_size], params[:customer_ids].split(","))

    redirect_to customer_user_filter_index_path(super_user), notice: "Printing"
  end
end
