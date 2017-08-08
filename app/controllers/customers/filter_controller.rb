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

    outcome = Customers::Filter.run(
      super_user: super_user,
      group_ids: param[:group_ids].split(","),
      has_email: param[:has_email],
      email_types: param[:email_types].split(","),
      living_place: param[:living_place].merge(
        states: param[:living_place][:states].present? ? param[:living_place][:states].split(",") : nil
      ),
      birthday: param[:birthday].merge(
        start_date: param[:birthday][:start_date].present? ? Date.parse(param[:birthday][:start_date]) : nil,
        end_date: param[:birthday][:end_date].present? ? Date.parse(param[:birthday][:end_date]) : nil
      ),
      reservation: param[:reservation].merge(
        start_date: param[:reservation][:start_date].present? ? Date.parse(param[:reservation][:start_date]).beginning_of_day : nil,
        end_date: param[:reservation][:end_date].present? ? Date.parse(param[:reservation][:end_date]).end_of_day : nil,
        menu_ids: param[:reservation][:menu_ids].present? ? param[:reservation][:menu_ids].split(",") : nil,
        staff_ids: param[:reservation][:staff_ids].present? ? param[:reservation][:staff_ids].split(",") : nil
      ),
      custom_ids: param[:custom_ids].split(",")
    )

    if outcome.valid?
      @customers = outcome.result
    else
      # render "api/v1/sessions/invalid_client", status: :unprocessable_entity
      head :unprocessable_entity
    end
  end
end
