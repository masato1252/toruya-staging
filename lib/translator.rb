module Translator
  def self.perform(message, options)
    options.each do |key, value|
      message = message.gsub(/%{#{key}}/, value)
    end

    message
  end
end
