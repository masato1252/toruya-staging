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
    outcome = Customers::Filter.run(
      super_user: super_user,
      group_ids: params[:group_ids].split(","),
      has_email: params[:has_email],
      email_types: params[:email_types].split(","),
      living_place: params[:living_place].merge(
        states: params[:living_place][:states].present? ? params[:living_place][:states].split(",") : nil
      ),
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
