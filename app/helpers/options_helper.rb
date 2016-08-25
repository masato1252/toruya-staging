module OptionsHelper
  def menu_options(menus)
    return unless menus
    menus.map { |m| { label: m.name, value: m.id, maxSeatNumber: m.max_seat_number } }
  end

  def staff_options(staffs, selected_menu)
    return unless staffs && selected_menu
    staffs.map { |s| { label: s.name, value: s.id.to_s, maxCustomers: s.staff_menus.find { |staff_menu| staff_menu.menu_id == selected_menu.id }.max_customers } }
  end

  def customer_options(customers)
    return [] unless customers.present?
    customers.map { |c| { label: c.name, value: c.id, level: c.state } }
  end
end
