module ReservationsHelper
  def dashboard_tag(&block)
    data = { }

    if params[:reservation_id]
      data[:controller] = "member-reservation-modal"
      data[:member_reservation_modal_target] = "#reservationModal#{params[:reservation_id]}"
    end

    content_tag(:div, capture(&block), data: data, class: "contents", id: "dashboard")
  end

  def reservation_staff_sentences(reservation)
    in_future_or_today = reservation.start_time.to_date >= Date.today
    reservation_staffs = reservation.staffs.to_a

    if in_future_or_today
      reservation_deleted_staff_names_sentence = reservation_staffs.find_all { |reservation_staff| reservation_staff.deleted_at }.map(&:name).join(", ")
    end

    {
      staffs_sentence: reservation_staffs.map(&:name).join(", ").presence,
      deleted_staffs_sentence: in_future_or_today ? reservation_staffs.find_all { |reservation_staff| reservation_staff.deleted_at }.map(&:name).join(", ").presence : nil
    }
  end

  def link_to_new_reservation(path, shop, options = { class: "BTNtarco" })
    link_to(path, options) do
      content_tag(:i, nil, class: "fa fa-calendar-plus-o fa-2x") +
      content_tag(:span, shop.display_name, class: "new-shop-reservation")
    end
  end
end
