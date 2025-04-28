# frozen_string_literal: true

module ReservationsHelper
  def customer_names_sentence(reservation)
    customer_names = reservation.customers.map(&:name)
    if customer_names.count > 1
      "#{customer_names.first} +#{customer_names.count - 1}"
    else
      customer_names.first
    end
  end

  def reservation_staff_sentences(reservation)
    in_future_or_today = reservation.start_time.to_date >= Date.current
    reservation_staffs = reservation.staffs.to_a

    if in_future_or_today
      reservation_deleted_staff_names_sentence = reservation_staffs.find_all { |reservation_staff| reservation_staff.deleted_at }.map(&:name).join(", ")
    end

    menu_staffs = reservation.reservation_staffs.group_by{|rs| rs.menu&.display_name || reservation.survey_activity.name }.map do |menu_name, reservation_staffs|
      "#{menu_name} (#{reservation_staffs.map { |rs| rs.staff.name }.join(", ")})"
    end.join(", ").html_safe

    {
      staffs_sentence: menu_staffs,
      deleted_staffs_sentence: in_future_or_today ? reservation_staffs.find_all { |reservation_staff| reservation_staff.deleted_at }.map(&:name).join(", ").presence : nil
    }
  end

  def link_to_new_reservation(path, text, options = { class: "BTNtarco" })
    link_to(path, options) do
      content_tag(:i, nil, class: "fa fa-calendar-plus fa-2x") +
      content_tag(:span, text, class: "new-shop-reservation")
    end
  end
end
