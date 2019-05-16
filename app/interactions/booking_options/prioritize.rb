module BookingOptions
  class Prioritize < ActiveInteraction::Base
    array :booking_options

    def execute
      # The order is prioritized by
      # menus number
      # required staffs number
      # required time
      booking_options.sort do |option1, option2|
        menus1 = option1.menus
        menus2 = option2.menus

        menu_number_versus = menus1.length <=> menus2.length

        if menu_number_versus == 0
          staff_number_versus = menus1.sum(:min_staffs_number) <=> menus2.sum(:min_staffs_number)

          if staff_number_versus == 0
            menus1.sum(:minutes) <=> menus2.sum(:minutes)
          else
            staff_number_versus
          end
        else
          menu_number_versus
        end
      end
    end
  end
end
