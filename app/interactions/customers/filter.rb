class Customers::Filter < ActiveInteraction::Base
  array :group_ids, default: nil
  string :address, default: nil
  # boolean :has_email, default: nil
  # array :email_types, default: nil
  object :dob_range, default: nil, class: Range
  string :custom_id, default: nil
  hash :reservation, default: nil do
    object :date_range, default: nil, class: Range
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :has_error, default: nil
    array :states, default: nil
  end

  def execute
  end
end
