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
  end

  def create
    param = params.permit!.to_h

    query = Customers::FilterQueryPayload.run!(param: params.permit!.to_h)
    outcome = Customers::Filter.run(query.merge(super_user: super_user))
    super_user.customer_query_filters.create( name: SecureRandom.uuid, query: query)

    if outcome.valid?
      @customers = outcome.result
    else
      # render "api/v1/sessions/invalid_client", status: :unprocessable_entity
      head :unprocessable_entity
    end
  end
end
