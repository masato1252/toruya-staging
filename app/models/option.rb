# frozen_string_literal: true

class Option
  include ActiveModel::Serializers::JSON
  attr_accessor :attrs

  def initialize(attrs = {})
    @attrs = attrs
    attrs.each do |key, value|
      # Option.send(:define_method, key) { value } https://stackoverflow.com/a/19368896/609365
      define_singleton_method(key) { value }
    end
  end

  def attributes
    attrs.each_with_object({}) do |(key, value), h|
      h[key] = value
    end
  end
end
