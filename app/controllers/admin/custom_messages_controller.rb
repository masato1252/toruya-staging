# frozen_string_literal: true

module Admin
  class CustomMessagesController < AdminController
    def scenarios; end

    def scenario
      @sequence_messages = CustomMessage.scenario_of(nil, params[:scenario]).order("after_days ASC")
    end

    def new
      @message = CustomMessage.new(content_type: CustomMessage::TEXT_TYPE, after_days: 3, flex_template: "video_description_card")
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
          content_type: params[:content_type],
        )

      return_json_response(outcome, { redirect_to: scenario_admin_custom_messages_path(params[:scenario]) })
    end

    def update
      outcome = CustomMessages::Users::Update.run(
        custom_message: CustomMessage.find(params[:id]),
        content: message_content,
        flex_template: params[:flex_template],
        after_days: params[:after_days],
        content_type: params[:content_type]
      )

      return_json_response(outcome, { redirect_to: scenario_admin_custom_messages_path(params[:scenario]) })
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


    private

    def message_content
      CustomMessages::BuildContent.run!(
        content_type: params[:content_type],
        flex_template: params[:flex_template],
        params: params.permit!.to_h
      )
    end
  end
end
