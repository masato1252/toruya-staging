json.menu do
  if @result[:menus].present?
    json.options @result[:menus].map { |m| { label: m.name, value: m.id } }
    json.selected_option @result[:selected_menu], :id, :min_staffs_number
  else
    json.options []
    json.selected_option ""
  end
end

json.staff do
  if @result[:staffs].present?
    json.options @result[:staffs].map { |s| { label: s.name, value: s.id } }
  else
    json.options []
  end
end
