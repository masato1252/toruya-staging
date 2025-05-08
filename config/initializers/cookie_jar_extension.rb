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
      self[cookie_name] = { value: value, domain: :all }.merge(options)
    end
  end
end

ActionDispatch::Cookies::CookieJar.include(CookieJarExtension)