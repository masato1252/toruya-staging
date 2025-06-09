# frozen_string_literal: true

module Staffs
  class Patch < ActiveInteraction::Base
    object :staff

    string :attribute
    string :first_name, default: nil
    string :last_name, default: nil
    string :phonetic_first_name, default: nil
    string :phonetic_last_name, default: nil
    string :phone_number, default: nil
    file :picture, default: nil
    string :introduction, default: nil
    array :staff_menus, default: nil

    def execute
      staff.with_lock do
        case attribute
        when "name"
          staff.update!(
            last_name: last_name,
            first_name: first_name,
            phonetic_last_name: phonetic_last_name,
            phonetic_first_name: phonetic_first_name
          )
        when "phone_number"
          formatted_phone = Phonelib.parse(phone_number, :jp).international(false)
          staff.staff_account.update!(phone_number: formatted_phone)
        when "staff_info"
          if picture
            staff.picture.purge
            staff.picture = picture
          end

          staff.introduction = introduction
          staff.save!
        when "staff_menus"
          staff.transaction do
            staff.staff_menus.destroy_all
            checked_staff_menus = staff_menus.select{ |attribute| attribute["checked"] == "true" }
            new_menu_attrs = checked_staff_menus.map do |attr|
              { menu_id: attr["menu_id"], max_customers: attr["max_customers"].presence || 1 }
            end

            staff.staff_menus.create(new_menu_attrs)
          end
        end

        if staff.errors.present?
          errors.merge!(staff.errors)
        end

        staff
      end
    end
  end
end
