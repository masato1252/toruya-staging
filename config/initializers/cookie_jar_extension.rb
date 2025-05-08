# frozen_string_literal: true

require 'active_support/concern'

module CookieJarExtension
  extend ActiveSupport::Concern

  included do
    def clear_across_domains(*cookie_names)
      domains = [
        'toruya.com', '.toruya.com', 'manager.toruya.com', 'booking.toruya.com',
        'toruya.test', '.toruya.test', 'manager.toruya.test', 'booking.toruya.test',
      ]

      cookie_names.each do |cookie_name|
        # Clear for all domains with all possible options
        delete(cookie_name, domain: :all, path: '/', secure: true, httponly: true)

        # Clear for specific domains
        domains.each do |domain|
          delete(cookie_name, domain: domain, path: '/', secure: true, httponly: true)
        end

        # Clear without domain (for current domain)
        delete(cookie_name, path: '/', secure: true, httponly: true)
      end
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)