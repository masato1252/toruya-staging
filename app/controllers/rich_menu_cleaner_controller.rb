# frozen_string_literal: true

class RichMenuCleanerController < ActionController::Base
  skip_before_action :verify_authenticity_token, only: [:verify]
  before_action :set_locale

  layout 'simple'

  protect_from_forgery with: :exception

  # Main page
  def index
  end

  def verify
    begin
      result = RichMenuCleaner::ListRichMenus.run(access_token: params[:access_token])

      if result.valid?
        render json: result.result
      else
        render json: {
          success: false,
          message: result.errors.full_messages.join(', ')
        }
      end
    rescue => e
      render json: {
        success: false,
        message: I18n.t('rich_menu_cleaner.failure.network_error', message: e.message)
      }
    end
  end

  def clean
    begin
      result = RichMenuCleaner::CleanAllRichMenus.run(access_token: params[:access_token])

      if result.valid?
        outcome = result.result
        if outcome[:success]
          redirect_to rich_menu_cleaner_index_path(locale: I18n.locale),
                      notice: outcome[:message]
        else
          redirect_to rich_menu_cleaner_index_path(locale: I18n.locale),
                      alert: outcome[:message]
        end
      else
        redirect_to rich_menu_cleaner_index_path(locale: I18n.locale),
                    alert: result.errors.full_messages.join(', ')
      end
    rescue => e
      redirect_to rich_menu_cleaner_index_path(locale: I18n.locale),
                  alert: I18n.t('rich_menu_cleaner.failure.network_error', message: e.message)
    end
  end

  private

  def set_locale
    locale = nil

    # 1. Check URL parameters
    if params[:locale].present? && %w[ja tw].include?(params[:locale])
      locale = params[:locale]
    # 2. Check session
    elsif session[:locale].present? && %w[ja tw].include?(session[:locale])
      locale = session[:locale]
    # 3. Browser language detection (via JavaScript-set cookie)
    elsif cookies[:browser_locale].present? && %w[ja tw].include?(cookies[:browser_locale])
      locale = cookies[:browser_locale]
    else
    # 4. Use default language
      locale = 'tw'
    end

    I18n.locale = locale
    session[:locale] = locale
  end
end