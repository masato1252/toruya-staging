class Customers::SavedFiltersController < DashboardController
  def show
    filter = super_user.customer_query_filters.find(params[:id])

    render json: filter.query
  end

  def create
    query = Customers::FilterQueryPayload.run!(param: params.permit!.to_h)
    super_user.customer_query_filters.create( name: params[:name], query: query)

    head :created
  end
end
