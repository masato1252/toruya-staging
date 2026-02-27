# frozen_string_literal: true

module Admin
  class CustomMessagesController < AdminController
    def scenarios; end

    def scenario
      @sequence_messages = CustomMessage.where(scenario: params[:scenario], locale: I18n.locale).order("nth_time ASC, after_days ASC")
    end

    def new
      @message = CustomMessage.new(content_type: CustomMessage::TEXT_TYPE, after_days: 3, flex_template: "video_description_card", nth_time: 1, locale: I18n.locale)
    end

    def edit
      @message = CustomMessage.find(params[:id])

      render action: :new
    end

    def create
      outcome =
        CustomMessages::Users::Create.run(
          scenario: params[:scenario],
          content: message_content,
          flex_template: params[:flex_template],
          after_days: params[:after_days],
          nth_time: params[:nth_time],
          content_type: params[:content_type],
          locale: params[:locale]
        )

      return_json_response(outcome, { redirect_to: scenario_admin_custom_messages_path(params[:scenario], locale: I18n.locale) })
    end

    def update
      message = CustomMessage.find(params[:id])
      outcome = CustomMessages::Users::Update.run(
        custom_message: message,
        content: message_content,
        flex_template: params[:flex_template],
        after_days: params[:after_days],
        nth_time: params[:nth_time],
        content_type: params[:content_type]
      )

      return_json_response(outcome, { redirect_to: scenario_admin_custom_messages_path(params[:scenario], locale: message.locale) })
    end

    def demo
      message = CustomMessage.new(
        content: message_content,
        content_type: params[:content_type],
        flex_template: params[:flex_template]
      )

      CustomMessages::Demo.run!(custom_message: message, receiver: current_user)

      head :ok
    end

    def bulk_send
      @bulk_type = params[:bulk_type]
      @scenario = bulk_scenario(@bulk_type)
      @saved_message = CustomMessage.find_by(scenario: @scenario, locale: I18n.locale)
      @target_users = bulk_target_users(@bulk_type)
    end

    def save_bulk_message
      bulk_type = params[:bulk_type]
      scenario = bulk_scenario(bulk_type)
      content = params[:content].presence || ""

      message = CustomMessage.find_by(scenario: scenario, locale: I18n.locale)
      if message
        message.update!(content: content)
      else
        CustomMessage.create!(
          scenario: scenario,
          content: content,
          content_type: CustomMessage::TEXT_TYPE,
          locale: I18n.locale,
          nth_time: 1,
          after_days: nil
        )
      end

      redirect_to bulk_send_admin_custom_messages_path(bulk_type), notice: "メッセージを保存しました"
    end

    def execute_bulk_send
      bulk_type = params[:bulk_type]
      scenario = bulk_scenario(bulk_type)
      content = params[:content].presence
      user_ids = params[:user_ids] || []

      unless content
        redirect_to bulk_send_admin_custom_messages_path(bulk_type), alert: "メッセージを入力してください"
        return
      end

      outcome = CustomMessages::Users::BulkSend.run(
        content: content,
        user_ids: user_ids.map(&:to_i),
        scenario: scenario
      )

      if outcome.valid?
        result = outcome.result
        redirect_to bulk_send_admin_custom_messages_path(bulk_type),
          notice: "送信完了: 成功 #{result[:success]}件 / 失敗 #{result[:failed]}件"
      else
        redirect_to bulk_send_admin_custom_messages_path(bulk_type),
          alert: "送信エラーが発生しました"
      end
    end

    private

    def message_content
      CustomMessages::BuildContent.run!(
        content_type: params[:content_type],
        flex_template: params[:flex_template],
        params: params.permit!.to_h
      )
    end

    def bulk_scenario(bulk_type)
      case bulk_type
      when "free_with_reservations"
        CustomMessages::Users::Template::BULK_FREE_WITH_RESERVATIONS
      when "incomplete_line"
        CustomMessages::Users::Template::BULK_FREE_INCOMPLETE_LINE_WITH_RESERVATIONS
      else
        raise ActionController::RoutingError, "Unknown bulk_type: #{bulk_type}"
      end
    end

    def bulk_target_users(bulk_type)
      users = User.joins(:subscription, :profile)
        .includes(:profile, :social_user, :social_account)
        .where(subscriptions: { plan_id: Subscription::FREE_PLAN_ID })
        .where("subscriptions.trial_expired_date < ?", Date.today)
        .where(id: users_with_external_booking_reservations)

      if bulk_type == "incomplete_line"
        users = users.joins(:social_account)
          .select { |u| !u.social_account&.line_settings_finished? }
      end

      Array(users)
    end

    def users_with_external_booking_reservations
      User.joins(reservations: :reservation_customers)
        .joins(:profile)
        .where.not(reservation_customers: { booking_page_id: nil })
        .joins("INNER JOIN customers ON customers.id = reservation_customers.customer_id")
        .where("customers.customer_phone_number IS NULL OR customers.customer_phone_number != profiles.phone_number")
        .distinct
        .pluck(:id)
    end
  end
end
