class Lines::UserBot::CustomMessagesController < Lines::UserBotDashboardController
  def update
    return compat_custom_message_mutation(:update) if compat_read_data_plane?

    service = params[:service_type].constantize.find_by(id: params[:service_id])

    if params[:id]
      outcome = CustomMessages::Customers::Update.run(
        message: CustomMessage.find_by!(id: params[:id], service: service),
        content: params[:content],
        after_days: params[:after_days].presence,
        before_minutes: params[:before_minutes].presence,
      )

      flash[:notice] = I18n.t("common.update_successfully_message")
    else
      outcome = CustomMessages::Customers::Create.run(
        service: service,
        scenario: params[:scenario],
        content: params[:content],
        after_days: params[:after_days].presence,
        before_minutes: params[:before_minutes].presence,
        locale: params[:locale]
      )

      flash[:notice] = I18n.t("common.create_successfully_message")
    end

    redirect_path =
      case service
      when OnlineService
        lines_user_bot_service_custom_messages_path(params[:service_id], business_owner_id: business_owner_id)
      when BookingPage
        lines_user_bot_booking_page_custom_messages_path(params[:service_id], business_owner_id: business_owner_id)
      when Shop
        lines_user_bot_settings_shop_custom_messages_path(shop_id: params[:service_id], business_owner_id: business_owner_id)
      when Lesson
        lines_user_bot_service_chapter_lesson_custom_messages_path(service_id: service.chapter.online_service_id, chapter_id: service.chapter_id, lesson_id: service.id, business_owner_id: business_owner_id)
      when Survey
        lines_user_bot_survey_custom_messages_path(id: service.id, business_owner_id: business_owner_id)
      when Episode
        lines_user_bot_service_episode_custom_messages_path(service_id: service.online_service_id, episode_id: service.id, business_owner_id: business_owner_id)
      end

    return_json_response(outcome, { redirect_to: redirect_path })
  end

  def demo
    return compat_custom_message_mutation(:demo) if compat_read_data_plane?

    service = params[:service_type].constantize.find_by(id: params[:service_id])

    message = CustomMessage.new(
      service: service,
      content: message_content,
      content_type: params[:content_type] || CustomMessage::TEXT_TYPE,
      locale: params[:locale]
    )

    CustomMessages::Demo.run!(custom_message: message, receiver: current_user)

    head :ok
  end

  def destroy
    return compat_custom_message_mutation(:destroy) if compat_read_data_plane?

    service = params[:service_type].constantize.find_by(id: params[:service_id])
    message = CustomMessage.find_by!(id: params[:id], service: service)

    redirect_path =
      case service
      when OnlineService
        lines_user_bot_service_custom_messages_path(params[:service_id], business_owner_id: business_owner_id)
      when BookingPage
        lines_user_bot_booking_page_custom_messages_path(params[:service_id], business_owner_id: business_owner_id)
      when Shop
        lines_user_bot_settings_shop_custom_messages_path(shop_id: params[:service_id], business_owner_id: business_owner_id)
      when Lesson
        lines_user_bot_service_chapter_lesson_custom_messages_path(service_id: service.chapter.online_service_id, chapter_id: service.chapter_id, lesson_id: service.id, business_owner_id: business_owner_id)
      when Episode
        lines_user_bot_service_episode_custom_messages_path(service_id: service.online_service_id, episode_id: service.id, business_owner_id: business_owner_id)
      end

    message.destroy

    redirect_to redirect_path
  end

  private

  def message_content
    CustomMessages::BuildContent.run!(
      content_type: params[:content_type] || CustomMessage::TEXT_TYPE,
      flex_template: params[:flex_template],
      params: params.permit!.to_h
    )
  end

  def compat_custom_message_mutation(action)
    owner_id = resolve_compat_owner_id(nil) || resolve_compat_current_user_id(nil)
    service_type = params[:service_type].to_s
    service_id = params[:service_id].to_i
    message_id = params[:id].to_i
    base_path =
      if service_type == "BookingPage" && service_id.positive?
        "/lines/user_bot/owner/#{owner_id}/booking_pages/#{service_id}/custom_messages"
      else
        "/lines/user_bot/owner/#{owner_id}/custom_messages"
      end
    body = {
      service_type: service_type,
      service_id: service_id,
      scenario: params[:scenario],
      content: action == :demo ? message_content : params[:content],
      after_days: params[:after_days],
      before_minutes: params[:before_minutes],
      locale: params[:locale],
      content_type: params[:content_type]
    }.compact

    result =
      case action
      when :update
        body[:id] = message_id if params[:id].present?
        compat_v1_put(base_path, body)
      when :demo
        compat_v1_post("#{base_path}/demo", body)
      when :destroy
        compat_v1_delete("#{base_path}/#{message_id}", body)
      end

    redirect_path = result&.dig("data", "redirect_to")
    if result&.dig("status") == "successful"
      return head :ok if action == :demo

      redirect_to redirect_path.presence || lines_user_bot_settings_path(business_owner_id: owner_id),
        notice: I18n.t(action == :destroy ? "common.delete_successfully_message" : "common.update_successfully_message")
    else
      if action == :demo
        head :unprocessable_entity
      else
        redirect_to redirect_path.presence || lines_user_bot_settings_path(business_owner_id: owner_id),
          alert: result&.dig("error_message") || I18n.t("common.operation_failed", default: "操作に失敗しました")
      end
    end
  end
end
