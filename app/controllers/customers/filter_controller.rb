class Customers::FilterController < DashboardController
  def index
    authorize! :read, :filter
    @body_class = "filter"
    menu_options = super_user.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name)
    end
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options = super_user.staffs.active.map do |staff|
      ::Options::StaffOption.new(id: staff.id, name: staff.name)
    end

    @filters = super_user.customer_query_filters
    @filtered_outcomes = super_user.filtered_outcomes.customers.active.order("created_at DESC")
    @has_shop = super_user.shops.exists?
  end

  def create
    authorize! :read, :filter
    query = FilterQueryPayload.run!(param: params.permit!.to_h)
    outcome = Customers::Filter.run(query.merge(super_user: super_user, current_user_staff: current_user_staff))

    if outcome.valid?
      @customers = outcome.result
    else
      # render "api/v1/sessions/invalid_client", status: :unprocessable_entity
      head :unprocessable_entity
    end
  end
end
