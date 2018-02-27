class Customers::SavedFiltersController < DashboardController
  def fetch
    @filter = super_user.customer_query_filters.find(params[:id])

    @filters = super_user.customer_query_filters

    render :show
  end

  def create
    query = FilterQueryPayload.run!(param: params.permit!.to_h)
    @filter = if params[:id]
                super_user.customer_query_filters.find(params[:id]).tap{ |filter| filter.update_attributes(name: params[:name], query: query)}
              else
                super_user.customer_query_filters.create(name: params[:name], query: query)
              end
    @filters = super_user.customer_query_filters

    render :show, status: :created
  end

  def delete
    @filter = super_user.customer_query_filters.find(params[:id])
    @filter.destroy

    render json: { savedFilterOptions: super_user.customer_query_filters.map{ |filter| { label: filter.name, value: filter.id } } }
  end
end
