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
        # Clear for all domains
        delete(cookie_name, domain: :all)

        # Clear for specific domains
        domains.each do |domain|
          delete(cookie_name, domain: domain)
        end

        # Clear without domain (for current domain)
        delete(cookie_name)
      end
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)