# frozen_string_literal: true

module SettingsHelper
  def synced_with(google_group, contact_groups)
    contact_groups.find { |contact_group| contact_group.google_group_id == google_group.id }
  end

  def check_setting_icon(completed)
    content_tag(:i, nil, class: "fa fa-check-circle #{completed && "done"}")
  end

  def booking_page_share_button_link(page)
    share_button_link(t("settings.booking_page.share_button_text"), booking_page_url(page.slug))
  end

  def share_button_link(btn_text, url)
    style = <<-STYLE.strip_heredoc.gsub("\n", "")
      display: inline-block;
      background-color: #aecfc8;
      border: 1px solid #84b3aa;
      border-radius: 6px;
      -moz-border-radius: 6px;
      -webkit-border-radius: 6px;
      -o-border-radius: 6px;
      -ms-border-radius: 6px;
      line-height: 40px;
      color: #fff;
      font-size: 14px;
      font-weight: bold;
      text-decoration: none;
      padding: 0 10px;
    STYLE

    link_to(btn_text, url, style: style, target: "_blank")
  end

  def booking_page_option_item(booking_page_option)
    booking_option = booking_page_option.booking_option

    tax_type = t("settings.booking_option.form.#{booking_option.tax_include ? "tax_include" : "tax_excluded"}")

    Option.new(
      id: booking_option.id,
      name: booking_option.show_name,
      minutes: booking_option.minutes,
      price: booking_option.price_text,
      price_text: booking_option.price_text,
      price_amount: booking_option.amount.fractional,
      start_at: booking_option.start_at ? l(booking_option.start_at) : l(booking_option.created_at),
      end_at: booking_option.end_at ? l(booking_option.end_at) : t("settings.booking_option.form.sale_forever"),
      is_free: booking_option.amount.zero?,
      is_online_payment: booking_page_option.is_online_payment?,
      option_type: booking_option.option_type,
      memo: booking_option.memo,
      menu_ids: booking_option.menu_relations.pluck(:menu_id)
    )
  end

  def booking_option_item(booking_option)
    Option.new(
      id: booking_option.id,
      name: booking_option.name,
      minutes: booking_option.minutes,
      price: booking_option.price_text,
      price_amount: booking_option.amount.fractional,
      start_at: booking_option.start_at ? l(booking_option.start_at) : l(booking_option.created_at),
      end_at: booking_option.end_at ? l(booking_option.end_at) : t("settings.booking_option.form.sale_forever"),
      is_free: booking_option.amount.zero?,
      cash_pay_required: booking_option.cash_pay_required?,
      memo: booking_option.memo,
      menu_ids: booking_option.menu_relations.pluck(:menu_id),
      option_type: booking_option.option_type
    )
  end

  def broadcast_deliver_at(broadcast)
    if broadcast.draft?
      broadcast.schedule_at ? I18n.l(broadcast.broadcast_at, format: :long_date_with_wday) : I18n.t("common.send_now_label")
    else
      I18n.l(broadcast.broadcast_at, format: :long_date_with_wday)
    end
  end

  def rich_menu_image_url(rich_menu, size = nil)
    Images::Process.run!(image: rich_menu.image, resize: size || "120") || rich_menu.default_image_url
  end

  def previous_path(default_path)
    if current_scope = cookies["current_scope_booking_option_id"]
      lines_user_bot_booking_option_path(current_scope, business_owner_id: Current.business_owner.id)
    elsif current_scope = cookies["current_scope_booking_page_id"]
      lines_user_bot_booking_page_path(current_scope, business_owner_id: Current.business_owner.id)
    else
      default_path
    end
  end
end
