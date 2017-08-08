class Customers::FilterController < DashboardController
  def index
    @body_class = "filter"
  end

  def create
    outcome = Customers::Filter.run(
      super_user: super_user,
      group_ids: params[:group_ids].split(","),
      has_email: params[:has_email],
      email_types: params[:email_types].split(","),
      living_place: params[:living_place].merge(states: params[:living_place][:states].split(",")),
      birthday: params[:birthday].merge(
        start_date: params[:birthday][:start_date].present? ? Date.parse(params[:birthday][:start_date]) : nil,
        end_date: params[:birthday][:end_date].present? ? Date.parse(params[:birthday][:end_date]) : nil
      ),
      reservation: params[:reservation].merge(
        start_date: params[:reservation][:start_date].present? ? Date.parse(params[:reservation][:start_date]).beginning_of_day : nil,
        end_date: params[:reservation][:end_date].present? ? Date.parse(params[:reservation][:end_date]).end_of_day : nil
      ),
      custom_ids: params[:custom_ids].split(",")
    )

    debugger
    if outcome.valid?
      @customers = outcome.result
    else
    end
  end
end
