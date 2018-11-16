class XhrConstraint
  def self.matches?(request)
    request.xhr?
  end
end
