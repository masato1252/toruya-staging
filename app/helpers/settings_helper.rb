module SettingsHelper
  def synced_with(google_group, contact_groups)
    contact_groups.find { |contact_group| contact_group.google_group_id == google_group.id }
  end

  def check_setting_icon(completed)
    content_tag(:i, nil, class: "fa fa-check-circle #{completed && "done"}")
  end

  def working_time_under_shop_menu
    return @working_time_under_shop_menu if defined?(@working_time_under_shop_menu)

    @working_time_under_shop_menu =
      if is_active_link?(request.original_fullpath, [["settings/working_time/staffs"]])
        !previous_controller_is("settings/staffs")
      end
  end
end
