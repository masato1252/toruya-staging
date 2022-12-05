class String
  def multibyte?
    chars.count < bytes.count
  end
end
