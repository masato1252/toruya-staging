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
      region: params[:region],
      cities: params[:email_types].split(","),
      custom_ids: params[:custom_ids].split(","),
      dob_range: params[:dob][:from].present? && params[:dob][:to].present? ? Date.parse(params[:dob][:from]).beginning_of_day..Date.parse(params[:dob][:to]).end_of_day : nil
    )

    if outcome.valid?
      @customers = outcome.result
    else
    end
  end
end
