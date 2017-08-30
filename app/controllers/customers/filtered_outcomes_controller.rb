class Customers::FilteredOutcomesController < DashboardController
  def fetch
    @filtered_outcome = super_user.filtered_outcomes.find(params[:id])

    render :show
  end
end
