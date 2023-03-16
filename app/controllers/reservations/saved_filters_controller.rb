# frozen_string_literal: true

class Reservations::SavedFiltersController < DashboardController
  def fetch
    @filter = Current.business_owner.reservation_query_filters.find(params[:id])

    @filters = Current.business_owner.reservation_query_filters

    render "customers/saved_filters/show"
  end

  def create
    query = FilterQueryPayload.run!(param: params.permit!.to_h)
    @filter = if params[:id]
                Current.business_owner.reservation_query_filters.find(params[:id]).tap{ |filter| filter.update(name: params[:name], query: query)}
              else
                Current.business_owner.reservation_query_filters.create(name: params[:name], query: query)
              end
    @filters = Current.business_owner.reservation_query_filters

    render "customers/saved_filters/show", status: :created
  end

  def delete
    @filter = Current.business_owner.reservation_query_filters.find(params[:id])
    @filter.destroy

    render json: { savedFilterOptions: Current.business_owner.reservation_query_filters.map{ |filter| { label: filter.name, value: filter.id } } }
  end
end
