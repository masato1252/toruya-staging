class Customers::Filter < ActiveInteraction::Base
  object :super_user, class: User
  array :group_ids, default: nil
  string :address, default: nil
  boolean :has_email, default: nil
  array :email_types, default: nil
  object :dob_range, default: nil, class: Range
  string :custom_id, default: nil
  hash :reservation, default: nil do
    boolean :has_reservation, default: nil
    object :date_range, default: nil, class: Range
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :has_error, default: nil
    array :states, default: nil
  end

  def execute
    scoped = super_user.customers

    scoped = scoped.where(contact_group_id: group_ids) if group_ids.present?
    scoped = scoped.where("address ilike ?", "%#{address}%") if address.present?

    if !has_email.nil?
      if has_email
        if email_types.present?
          email_type_sql = email_types.map {|type| "email_types like '%#{type}%'"}.join(" OR ")
          scoped = scoped.where(email_type_sql)
        else
          scoped = scoped.where("email_types is not NULL")
        end
      else
        scoped = scoped.where("email_types is NULL")
      end
    end

    scoped = scoped.where(birthday: dob_range) if dob_range.present?
    scoped = scoped.where("custom_id ilike ?", "%#{custom_id}%") if custom_id.present?
    scoped
  end
end
