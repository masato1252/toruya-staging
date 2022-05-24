# frozen_string_literal: true

module CustomMessages
  class BuildContent < ActiveInteraction::Base
    string :content_type
    string :flex_template
    hash :params, default: nil do
      string :title, default: nil
      string :context, default: nil
      string :picture_url, default: nil
      string :content_url, default: nil
      string :button_text, default: nil
    end

    def execute
      case content_type
      when CustomMessage::TEXT_TYPE
        params[:content]
      when CustomMessage::FLEX_TYPE
        case flex_template
        when "video_description_card"
          {
            title: params[:title],
            context: params[:context],
            picture_url: params[:picture_url],
            content_url: params[:content_url],
            button_text: params[:button_text]
          }.to_json
        end
      end
    end
  end
end
