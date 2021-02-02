# frozen_string_literal: true

class HashieSerializer
  def self.dump(hash)
    hash
  end

  def self.load(hash)
    Hashie::Mash.new(hash || {})
  end
end
