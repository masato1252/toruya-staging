json.menu do
  if @result[:category_menus].present?
    json.group_options menu_group_options(@result[:category_menus])
    json.partial! "selected_option", menu: @result[:selected_menu]
  else
    json.group_options []
    json.selected_option ""
  end
end

json.partial! "staff_options", staffs: @result[:staffs], menu: @result[:selected_menu]
