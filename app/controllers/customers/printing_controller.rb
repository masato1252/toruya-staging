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
    query = Customers::FilterQueryPayload.run!(param: params.permit!.to_h)
    filter_outcome = super_user.filter_outcomes.create(filter_id: params[:filter_id], query: query)

    CustomersPrintingJob.perform_later(filter_outcome, params[:page_size], params[:customer_ids].split(","))

    render json: { result: super_user.filter_outcomes.active.pluck(:id) }
  end
end
