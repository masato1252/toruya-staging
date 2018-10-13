module SettingsHelper
  def synced_with(google_group, contact_groups)
    contact_groups.find { |contact_group| contact_group.google_group_id == google_group.id }
  end

  def check_setting_icon(completed)
    content_tag(:i, nil, class: "fa fa-check-circle #{completed && "done"}")
  end
end
