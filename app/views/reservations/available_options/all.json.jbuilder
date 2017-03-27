json.menu do
  json.group_options menu_group_options(@menus_result[:category_with_menu_options])
end

json.partial! "staff_options", staffs: @staff_options, menu: []
