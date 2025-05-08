# frozen_string_literal: true

require 'active_support/concern'

module CookieJarExtension
  extend ActiveSupport::Concern
  DOMAINS = [
    'toruya.com', '.toruya.com', 'manager.toruya.com', 'booking.toruya.com',
    'toruya.test', '.toruya.test', 'manager.toruya.test', 'booking.toruya.test',
  ]

  included do
    def clear_across_domains(*cookie_names)
      cookie_names.each do |cookie_name|
        # Clear for all domains with all possible options
        delete(cookie_name, domain: :all, path: '/', secure: true, httponly: true)

        # Clear for specific domains
        DOMAINS.each do |domain|
          delete(cookie_name, domain: domain, path: '/', secure: true, httponly: true)
        end

        # Clear without domain (for current domain)
        delete(cookie_name, path: '/', secure: true, httponly: true)
      end
    end

    def set_across_domains(cookie_name, value, options = {})
      default_options = { path: '/', secure: true, httponly: true }
      options = default_options.merge(options)

      # Set for all domains
      self[cookie_name] = { value: value, domain: :all }.merge(options)

      # Set for specific domains
      DOMAINS.each do |domain|
        self[cookie_name] = { value: value, domain: domain }.merge(options)
      end

      # Set for current domain
      self[cookie_name] = { value: value }.merge(options)
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)