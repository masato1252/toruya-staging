class Lines::UserBot::CustomMessagesController < Lines::UserBotDashboardController
  def update
    service = params[:service_type].constantize.find_by(id: params[:service_id])

    if params[:id]
      outcome = CustomMessages::Customers::Update.run(
        message: CustomMessage.find_by!(id: params[:id], service: service),
        content: params[:content],
        after_days: params[:after_days].presence,
        before_minutes: params[:before_minutes].presence,
      )
    else
      outcome = CustomMessages::Customers::Create.run(
        service: service,
        scenario: params[:scenario],
        content: params[:content],
        after_days: params[:after_days].presence,
        before_minutes: params[:before_minutes].presence,
        locale: params[:locale]
      )
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
      when Episode
        lines_user_bot_service_episode_custom_messages_path(service_id: service.online_service_id, episode_id: service.id, business_owner_id: business_owner_id)
      end

    return_json_response(outcome, { redirect_to: redirect_path })
  end

  def demo
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
end
