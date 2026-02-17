# frozen_string_literal: true

require 'active_support/concern'

module CookieJarExtension
  extend ActiveSupport::Concern

  included do
    def clear_across_domains(*cookie_names)
      cookie_names.each do |cookie_name|
        # domain: :all で設定されたCookieも確実に削除するため、両方のパターンで削除
        delete(cookie_name, domain: :all)
        delete(cookie_name)
      end
    end

    def set_across_domains(cookie_name, value, options = {})
      self[cookie_name] = { value: value, domain: :all }.merge(options)
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)