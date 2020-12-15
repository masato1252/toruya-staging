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
      if message.present? && BOOTSTRAP_FLASH_MSG.keys.include?(msg_type)
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

  def present(klass, *args)
    yield klass.new(*args)
  end

  def modal_link_to(*args, &block)
    default_options = {
      data: {
        controller: "modal",
        modal_target: "#dummyModal",
        action: "click->modal#popup",
        class: "modal-link"
      }
    }

    if block_given?
      path = args.first
      options = args[1] || {}

      link_to capture(&block),"#", options.reverse_merge(default_options.merge("data-modal-path": path))
    else
      text = args.first
      path = args.second
      options = args[2] || {}

      link_to text,"#", options.reverse_merge(default_options.merge("data-modal-path": path))
    end
  end

  def jump_out_modal(path, options={})
    data = {}
    data[:controller] = "modal"
    data[:modal_target] = "#dummyModal"
    data[:modal_jump_out] = true
    data[:modal_path] = path

    if options[:static]
      data[:modal_static] = true
    end

    content_tag(:template, nil, data: data)
  end

  def translation_resuce
    begin
      yield
    rescue
      ""
    end
  end
  alias_method :image_rescue, :translation_resuce
end
