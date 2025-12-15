# frozen_string_literal: true

require 'active_support/concern'

module CookieJarExtension
  extend ActiveSupport::Concern

  included do
    def clear_across_domains(*cookie_names)
      cookie_names.each do |cookie_name|
        delete(cookie_name)
      end
    end

    def set_across_domains(cookie_name, value, options = {})
      # Add same_site: :none and secure: true for production to support cross-site redirects
      default_options = { value: value, domain: :all }
      
      if Rails.env.production?
        default_options.merge!(
          secure: true,
          same_site: :none
        )
      end
      
      self[cookie_name] = default_options.merge(options)
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)