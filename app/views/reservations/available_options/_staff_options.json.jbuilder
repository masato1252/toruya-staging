# frozen_string_literal: true

json.staff do
  if staffs.present?
    json.options staff_options(staffs, menu)
  else
    json.options []
  end
end
