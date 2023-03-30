# frozen_string_literal: true

require "message_encryptor"

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

  def custom_bootstrap_flash
    flash_messages = []
    flash.each do |type, message|
      type = "success" if type == "notice"
      type = "error" if type == "alert"
      type = "info" if type == "info"
      type = "warning" if type == "warning"
      text = "<script>toastr.#{type}('#{message}');</script>"
        flash_messages << text.html_safe if message
    end
    flash_messages.join("\n").html_safe
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

  # line_login_url(current_owner.social_account, request.url, foo: "bar"),
  def line_login_url(social_account, oauth_redirect_to_url, *args)
    options = args.extract_options!
    encrypted_id = MessageEncryptor.encrypt(social_account&.id)
    cookies[:oauth_social_account_id] = { value: encrypted_id, expires: 1.year }
    cookies.delete(:who)

    if social_account&.is_login_available?
      options.merge!(
        prompt: "consent", bot_prompt: "aggressive", oauth_redirect_to_url: oauth_redirect_to_url, oauth_social_account_id: encrypted_id
      )

      user_line_omniauth_authorize_path(options)
    else
      nil
    end
  end

  def toruya_line_login_url(oauth_redirect_to_url, *args)
    options = args.extract_options!
    encrypted_content = MessageEncryptor.encrypt(CallbacksController::TORUYA_USER)
    cookies[:who] = { value: encrypted_content, expires: 1.year }

    options.merge!(
      prompt: "consent", bot_prompt: "aggressive", oauth_redirect_to_url: oauth_redirect_to_url, who: encrypted_content
    )

    user_line_omniauth_authorize_path(options)
  end

  def embed_tour_video(key)
    %Q|<iframe width='100%' height='auto' src='https://www.youtube.com/embed/#{TOURS_VIDEOS[key]}' title='YouTube video player' frameborder='0' allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture' allowfullscreen></iframe>|.html_safe
  end

  def mobile_only
    if mobile_types.include?(device_detector.device_type)
      yield
    end
  end

  def non_mobile
    if mobile_types.exclude?(device_detector.device_type)
      yield
    end
  end

  def qrcode_img(url)
    qrcode = RQRCode::QRCode.new(url)
    png = qrcode.as_png(
      bit_depth: 1,
      border_modules: 4,
      color_mode: ChunkyPNG::COLOR_GRAYSCALE,
      color: "black",
      file: nil,
      fill: "white",
      module_px_size: 6,
      resize_exactly_to: false,
      resize_gte_to: false,
      size: 120
    )
    image_tag(png.to_data_url)
  end

  private

  def mobile_types
    ["smartphone", "feature phone"]
  end
end
