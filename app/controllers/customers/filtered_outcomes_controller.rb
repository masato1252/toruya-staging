class Customers::FilteredOutcomesController < DashboardController
  def fetch
    @filtered_outcome = super_user.filter_outcomes.find(params[:id])

    render :show
  end
end
