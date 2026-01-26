# frozen_string_literal: true

require "line_client"

module SocialCustomers
  class ConnectWithCustomer < ActiveInteraction::Base
    object :social_customer
    object :customer

    def execute
      other_social_customers = SocialCustomer.where.not(id: social_customer.id).where(user_id: social_customer.user_id, customer_id: customer.id)

      if other_social_customers.exists?
        other_social_customers.update_all(customer_id: nil)
      end

      # まずcustomerを紐付け（これが最重要）
      social_customer.update!(customer_id: customer.id)

      # 紐付け成功後にLINE通知とリッチメニュー設定
      begin
        LineClient.send(social_customer, I18n.t("line.bot.connected_successfully"))
        RichMenus::Connect.run(social_target: social_customer, social_rich_menu: social_account.current_rich_menu) if social_account.current_rich_menu
      rescue => e
        # LINE送信失敗してもcustomer紐付けは成功しているのでログだけ出力
        Rails.logger.error("[SocialCustomers::ConnectWithCustomer] LINE送信失敗: #{e.message}")
        Rollbar.error(e, social_customer_id: social_customer.id, customer_id: customer.id)
      end
    end

    private

    def social_account
      @social_account ||= social_customer.social_account
    end
  end
end
