module SettingsHelper
  def synced_with(google_group, contact_groups)
    contact_groups.find { |contact_group| contact_group.google_group_id == google_group.id }
  end

  def check_setting_icon(completed)
    content_tag(:i, nil, class: "fa fa-check-circle #{completed && "done"}")
  end

  def booking_url(page)
    @booking_url ||= Rails.configuration.x.env.staging? ? booking_page_url(page) : booking_page_url(page, subdomain: :booking)
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

    link_to(t("settings.booking_page.share_button_text"), booking_url(page), style: style)
  end
end
