# frozen_string_literal: true

module OrderId
  def self.generate
    SecureRandom.hex(8).upcase
  end
end
