# frozen_string_literal: true

class XhrConstraint
  def self.matches?(request)
    request.xhr?
  end
end
