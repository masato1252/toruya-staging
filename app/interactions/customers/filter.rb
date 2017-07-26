class Customers::Filter < ActiveInteraction::Base
  object :super_user, class: User
  array :group_ids, default: nil
  string :region, default: nil
  array :cities, default: nil
  boolean :has_email, default: nil
  array :email_types, default: nil
  object :dob_range, default: nil, class: Range
  array :custom_ids, default: nil
  hash :reservation, default: nil do
    boolean :has_reservation, default: nil
    object :date_range, default: nil, class: Range
    array :menu_ids, default: nil
    array :staff_ids, default: nil
    boolean :has_error, default: nil
    array :states, default: nil
  end

  def execute
    scoped = super_user.customers.includes(:rank, :contact_group, :updated_by_user)

    scoped = scoped.where(contact_group_id: group_ids) if group_ids.present?

    if region.present?
      if cities.present?
        cities_sql = cities.map {|city| "address = '#{region} #{city}'"}.join(" OR ")
        scoped = scoped.where(cities_sql)
      else
        scoped = scoped.where("address ilike ?", "#{region}%")
      end
    end

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

    if custom_ids.present?
      custom_ids_sql = custom_ids.map {|custom_id| "custom_id ilike '%#{custom_id}%'"}.join(" OR ")
      scoped = scoped.where(custom_ids_sql)
    end

    scoped
  end
end
