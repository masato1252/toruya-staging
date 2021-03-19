# frozen_string_literal: true

json.menu do
  if @result[:category_menu_options].present?
    json.group_options menu_group_options(@result[:category_menu_options])
    json.partial! "selected_option", menu_option: @result[:selected_menu_option]
  else
    json.group_options []
    json.selected_option ""
  end
end

json.partial! "staff_options", staffs: @result[:staff_options], menu: @result[:selected_menu_option]
