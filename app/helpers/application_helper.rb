module ApplicationHelper
 BOOTSTRAP_FLASH_MSG = {
    'success' => 'alert-success',
    'error' => 'alert-danger',
    'alert' => 'alert-warning',
    'notice' => 'alert-info'
  }

  def bootstrap_class_for(flash_type)
    BOOTSTRAP_FLASH_MSG.fetch(flash_type, flash_type.to_s)
  end

  def flash_messages(opts = {})
    flash.each do |msg_type, message|
      if message.present?
        concat(content_tag(:div, message, :class => "alert #{bootstrap_class_for(msg_type)} fade in") do
          concat content_tag(:button, 'x', :class => "close", :data => { :dismiss => 'alert' })
          concat message.html_safe
        end)
      end
    end
    nil
  end

  def notification_messages
    (@notification_messages || []).each do |message|
      concat(content_tag(:div, message, :class => "notification alert alert-info fade in") do
        concat content_tag(:button, 'x', :class => "close", :data => { :dismiss => 'alert' })
        concat message.html_safe
      end)
    end
    nil
  end

  def body_class
    "#{controller_name}-container #{@body_class}"
  end

  def admin_only(&block)
    if admin?
      block.call
    end
  end

  def manager_only(&block)
    if manager?
      block.call
    end
  end

  def present(klass, *args)
    yield klass.new(*args)
  end

  def warning_link(text, path)
    link_to text, "#", data: {
      controller: "warning-modal",
      warning_modal_target: "#warningModal",
      action: "click->warning-modal#popup",
      warning_modal_warning_path: path
    }
  end
end
