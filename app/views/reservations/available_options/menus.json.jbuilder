json.menu do
  if @menus.present?
    json.options @menus.map { |m| { label: m.name, value: m.id } }
    json.selected_option @selected_menu, :id, :min_staffs_number
  else
    json.options []
    json.selected_option ""
  end
end

json.staff do
  if @staffs.present?
    json.options @staffs.map { |s| { label: s.name, value: s.id } }
  else
    json.options []
  end
end
