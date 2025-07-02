# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'

module RichMenuCleaner
  class CleanAllRichMenus < ActiveInteraction::Base
    string :access_token

    validate :access_token_presence

    def execute
      begin
        # First list all Rich Menus using compose
        list_result = compose(RichMenuCleaner::ListRichMenus, access_token: access_token.strip)

        # list_result is directly the hash returned by ListRichMenus#execute
        return list_result unless list_result[:success]

        rich_menus = list_result[:rich_menus]

        return success_response(I18n.t('rich_menu_cleaner.success.none_to_delete')) if rich_menus.empty?

        # Delete each Rich Menu one by one
        success_count = 0
        failed_count = 0

        rich_menus.each do |menu|
          if delete_rich_menu(menu['richMenuId'])
            success_count += 1
          else
            failed_count += 1
          end
        end

        # Generate result report
        total_count = rich_menus.size

        if failed_count == 0
          success_response(I18n.t('rich_menu_cleaner.success.all_deleted', count: total_count))
        elsif success_count == 0
          error_response(I18n.t('rich_menu_cleaner.failure.all_failed', count: total_count))
        else
          success_response(I18n.t('rich_menu_cleaner.success.partial_success',
                                 success: success_count, failed: failed_count))
        end

      rescue => e
        error_response(I18n.t('rich_menu_cleaner.failure.network_error', message: e.message))
      end
    end

    private

    def access_token_presence
      errors.add(:access_token, I18n.t('rich_menu_cleaner.errors.access_token_required')) if access_token.blank?
    end

    def success_response(message)
      {
        success: true,
        message: message
      }
    end

    def error_response(message)
      {
        success: false,
        message: message
      }
    end

    # Delete specified Rich Menu (DELETE /v2/bot/richmenu/{richMenuId})
    def delete_rich_menu(rich_menu_id)
      uri = URI("https://api.line.me/v2/bot/richmenu/#{rich_menu_id}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Delete.new(uri)
      request['Authorization'] = "Bearer #{access_token.strip}"

      response = http.request(request)
      response.code.to_i == 200
    rescue
      false
    end
  end
end