module RandomCode
  CODE_CHARSET = (1..9).to_a.freeze

  def self.generate(number)
    Array.new(number) { CODE_CHARSET.sample }.join
  end
end
