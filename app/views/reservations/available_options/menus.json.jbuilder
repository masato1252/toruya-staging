json.menu do
  if @result[:menu_options].present?
    json.options @result[:menu_options].map { |m| { label: m.name, value: m.id } }
    json.selected_option @result[:selected_menu], :id, :min_staffs_number
  else
    json.options []
    json.selected_option ""
  end
end

json.staff do
  if @result[:staff_options].present?
    json.options @result[:staff_options].map { |s| { label: s.name, value: s.id } }
  else
    json.options []
  end
end
