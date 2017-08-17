class Customers::SavedFiltersController < DashboardController
  def fetch
    @filter = super_user.customer_query_filters.find(params[:id])

    @filters = super_user.customer_query_filters

    render :show
  end

  def create
    query = Customers::FilterQueryPayload.run!(param: params.permit!.to_h)
    @filter = super_user.customer_query_filters.create( name: params[:name], query: query)
    @filters = super_user.customer_query_filters

    render :show, status: :created
  end
end
