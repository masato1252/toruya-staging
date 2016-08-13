json.menu do
  json.selected_option @menu, :id, :min_staffs_number
end

json.staff do
  if @staffs.present?
    json.options @staffs.map { |s| { label: s.name, value: s.id } }
  else
    json.options []
  end
end
