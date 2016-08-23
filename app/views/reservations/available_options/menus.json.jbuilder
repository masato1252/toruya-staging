json.menu do
  if @result[:menus].present?
    json.options menu_options(@result[:menus])
    json.partial! "selected_option", menu: @result[:selected_menu]
  else
    json.options []
    json.selected_option ""
  end
end

json.partial! "staff_options", staffs: @result[:staffs], menu: @result[:selected_menu]
