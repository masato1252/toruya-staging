# frozen_string_literal: true

module UserBotCookies
  PREPEND = "user_bot".freeze

  def user_bot_cookies(key)
    cookies.encrypted[prepend_key(key)]
  end

  def write_user_bot_cookies(key, value)
    cookies.clear_across_domains(prepend_key(key))
    cookies.encrypted[prepend_key(key)] = { value: value, expires: 20.years.from_now, domain: :all }
  end

  def delete_user_bot_cookies(key)
    cookies.clear_across_domains(prepend_key(key))
  end

  def prepend_key(key)
    "#{PREPEND}_#{key}"
  end
end
