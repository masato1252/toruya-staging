json.menu do
  json.group_options menu_group_options(@menus_result[:category_with_menu_options])
  json.partial! "selected_option", menu_option: @menus_result[:menu_options].first
end

json.partial! "staff_options", staffs: @staff_options, menu: []
