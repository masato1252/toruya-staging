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
    cookies[:oauth_social_account_id] = {
      value: encrypted_id,
      expires: 100.year,
      domain: :all
    }
    cookies.delete(:who, domain: :all)
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

  def toruya_new_line_account_url(oauth_redirect_to_url, *args)
    options = args.extract_options!
    toruya_user = Current.business_owner.locale_is?(:tw) ? CallbacksController::TW_TORUYA_USER : CallbacksController::TORUYA_USER
    encrypted_content = MessageEncryptor.encrypt(toruya_user)
    cookies[:who] = {
      value: encrypted_content,
      domain: :all,
      expires: 100.year
    }

    options.merge!(
      prompt: "consent", bot_prompt: "aggressive", oauth_redirect_to_url: oauth_redirect_to_url, who: encrypted_content, existing_owner_id: root_user.id, locale: params[:locale]
    )

    user_line_omniauth_authorize_path(options)
  end

  def toruya_line_login_url(oauth_redirect_to_url, *args)
    options = args.extract_options!
    toruya_user = params[:locale] == 'tw' ? CallbacksController::TW_TORUYA_USER : CallbacksController::TORUYA_USER
    encrypted_content = MessageEncryptor.encrypt(toruya_user)
    cookies[:who] = {
      value: encrypted_content,
      expires: 100.year,
      domain: :all,
    }

    options.merge!(
      prompt: "consent", bot_prompt: "aggressive", oauth_redirect_to_url: oauth_redirect_to_url, who: encrypted_content, locale: params[:locale]
    )

    user_line_omniauth_authorize_path(options)
  end

  def embed_tour_video(key)
    %Q|<iframe width='100%' height='auto' src='https://www.youtube.com/embed/#{TOURS_VIDEOS[key]}' title='YouTube video player' frameborder='0' allow='accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture' allowfullscreen></iframe>|.html_safe
  end

  def is_not_phone?
    wider_device_types.include?(device_detector.device_type)
  end

  def is_phone?
    !is_not_phone?
  end

  def not_phone
    if is_not_phone?
      yield
    end
  end

  def mobile_only
    if wider_device_types.exclude?(device_detector.device_type)
      yield
    end
  end

  def non_mobile
    if wider_device_types.include?(device_detector.device_type)
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

  def bot_sale_page_path(sale_page)
    if sale_page.draft
      if sale_page.is_booking_page?
        new_lines_user_bot_sales_booking_page_path(business_owner_id: business_owner_id, sale_page_id: sale_page.id)
      else
        new_lines_user_bot_sales_online_service_path(business_owner_id: business_owner_id, sale_page_id: sale_page.id)
      end
    else
      lines_user_bot_sale_path(sale_page, business_owner_id: business_owner_id)
    end
  end

  def booking_price_desc(booking_option)
    "#{booking_option.price_text} #{"<i class='fa fa-ticket-alt text-gray-500'></i> #{booking_option.amount / booking_option.ticket_quota} #{I18n.t("common.unit")} X #{booking_option.ticket_quota} #{I18n.t("common.times")}" if booking_option.ticket_enabled?}".html_safe
  end

  def toruya_line_friend_url
    "https://line.me/R/ti/p/@#{Rails.application.secrets[I18n.locale][:toruya_user_bot_basic_id]}"
  end

  private

  def wider_device_types
    ["desktop"]
  end

  def mobile_types
    ["smartphone", "feature phone", "tablet"]
  end
end
