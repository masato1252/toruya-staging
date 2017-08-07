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
      living_place: { inside: params[:living_place][:inside], states: params[:living_place][:states].split(",") },
      birthday: {
        query_type: params[:birthday][:query_type],
        start_date: Date.parse(params[:birthday][:start_date]),
        end_date: Date.parse(params[:birthday][:end_date])
      },
      custom_ids: params[:custom_ids].split(",")
    )

    if outcome.valid?
      @customers = outcome.result
    else
    end
  end
end
