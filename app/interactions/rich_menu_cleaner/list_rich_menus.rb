# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module RichMenuCleaner
  class ListRichMenus < ActiveInteraction::Base
    string :access_token

    validate :access_token_presence

    def execute
      begin
        uri = URI('https://api.line.me/v2/bot/richmenu/list')
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true

        request = Net::HTTP::Get.new(uri)
        request['Authorization'] = "Bearer #{access_token.strip}"
        request['Content-Type'] = 'application/json'

        response = http.request(request)

        case response.code.to_i
        when 200
          data = JSON.parse(response.body)
          rich_menus = data['richmenus'] || []

          {
            success: true,
            rich_menus: rich_menus,
            count: rich_menus.size,
            message: rich_menus.empty? ?
              I18n.t('rich_menu_cleaner.list.none_found') :
              I18n.t('rich_menu_cleaner.list.found', count: rich_menus.size)
          }
        when 401
          {
            success: false,
            message: I18n.t('rich_menu_cleaner.failure.invalid_token')
          }
        when 403
          {
            success: false,
            message: I18n.t('rich_menu_cleaner.failure.insufficient_permission')
          }
        else
          {
            success: false,
            message: I18n.t('rich_menu_cleaner.failure.api_error',
                           code: response.code, message: response.body)
          }
        end
      rescue JSON::ParserError => e
        {
          success: false,
          message: I18n.t('rich_menu_cleaner.failure.network_error', message: "JSON parse error: #{e.message}")
        }
      rescue => e
        {
          success: false,
          message: I18n.t('rich_menu_cleaner.failure.network_error', message: e.message)
        }
      end
    end

    private

    def access_token_presence
      errors.add(:access_token, I18n.t('rich_menu_cleaner.errors.access_token_required')) if access_token.blank?
    end
  end
end