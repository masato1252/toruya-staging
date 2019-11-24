module SettingsHelper
  def synced_with(google_group, contact_groups)
    contact_groups.find { |contact_group| contact_group.google_group_id == google_group.id }
  end

  def check_setting_icon(completed)
    content_tag(:i, nil, class: "fa fa-check-circle #{completed && "done"}")
  end

  def booking_url(page)
    booking_page_url(page)
  end

  def booking_page_share_button_link(page)
    style = <<-STYLE.strip_heredoc.gsub!("\n", "")
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

    link_to(t("settings.booking_page.share_button_text"), booking_url(page), style: style, target: "_blank")
  end

  def booking_option_item(booking_option)
    tax_type = t("settings.booking_option.form.#{booking_option.tax_include ? "tax_include" : "tax_excluded"}")

    Option.new(
      id: booking_option.id,
      name: booking_option.display_name,
      minutes: booking_option.minutes,
      price: "#{booking_option.amount.format(:ja_default_format)}(#{tax_type})",
      start_at: booking_option.start_at ? l(booking_option.start_at) : l(booking_option.created_at),
      end_at: booking_option.end_at ? l(booking_option.end_at) : t("settings.booking_option.form.sale_forever"),
      memo: booking_option.memo
    )
  end
end
