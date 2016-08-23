json.menu do
  json.partial! "selected_option", menu: @menu
end

json.partial! "staff_options", staffs: @staffs, menu: @menu
