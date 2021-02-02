# frozen_string_literal: true

class Customers::PrintingController < DashboardController
  def new
    @customer = super_user.customers.contact_groups_scope(current_user_staff).find(params[:customer_id]).with_google_contact
    @page_size = params[:page_size]

    options = {
      pdf: "customer",
      title: @customer.name,
      show_as_html: params.key?('debug')
    }.merge!(Customers::PrintingConfig.run!(page_size: @page_size))

    render options
  end

  def create
    query = FilterQueryPayload.run!(param: params.permit!.to_h)
    filtered_outcome = super_user.filtered_outcomes.create(params[:filtered_outcome].merge(query: query))

    CustomersPrintingJob.perform_later(filtered_outcome, params[:customer_ids].split(","))

    render json: { filtered_outcome_options: view_context.filtered_outcome_options(super_user.filtered_outcomes.active.order("created_at DESC")) }
  end
end
