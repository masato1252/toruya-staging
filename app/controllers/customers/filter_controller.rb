class Customers::FilterController < DashboardController
  def index
    @body_class = "filter"
    menu_options = super_user.menus.map do |menu|
      ::Options::MenuOption.new(id: menu.id, name: menu.display_name)
    end
    @menu_result = Menus::CategoryGroup.run!(menu_options: menu_options)

    @staff_options = super_user.staffs.map do |staff|
      ::Options::StaffOption.new(id: staff.id, name: staff.name)
    end

    @filters = super_user.customer_query_filters
    @filtered_outcomes = super_user.filtered_outcomes.active.order("created_at DESC")
    @ranks = super_user.ranks.order("id DESC") # For regular first then VIP
  end

  def create
    query = Customers::FilterQueryPayload.run!(param: params.permit!.to_h)
    outcome = Customers::Filter.run(query.merge(super_user: super_user))

    if outcome.valid?
      @customers = outcome.result
    else
      # render "api/v1/sessions/invalid_client", status: :unprocessable_entity
      head :unprocessable_entity
    end
  end
end
