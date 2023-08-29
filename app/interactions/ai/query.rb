# frozen_string_literal: true

module Ai
  class Query < ActiveInteraction::Base
    string :user_id
    string :question
    string :prompt, default: nil

    validate :validate_question

    def execute
      if Rails.env.development?
        message ="企業情報を変更するには、以下の手順を実行します。\n\n1. ユーザーメニューから「設定画面」を選択します。\n2. アカウント設定メニューの「アカウント登録情報」欄から「企業情報」メニ
ューを選択します。\n3. 変更したい情報を選択して編集し、「保存」ボタンを押します。\n\n詳細な手順と画像は、以下のリンク先のページで確認することができます。\n[企業情報を変更する](https://toruya.com/help/setting_companyinfo/)"

        references = ["https://toruya.com/help/setting_companyinfo/"]
      else
        response = AI_QUERY.perform(user_id, question, prompt)
        message = response.to_s
      end

      {
        message: message,
        references: references
      }
    end

    private

    def validate_question
      if question.blank?
        errors.add(:question, :required)
      end
    end
  end
end
