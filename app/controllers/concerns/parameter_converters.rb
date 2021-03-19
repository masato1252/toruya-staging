# frozen_string_literal: true

module ParameterConverters
  extend ActiveSupport::Concern

  def repair_nested_params(obj = params)
    obj.each do |key, value|
      if value.is_a?(ActionController::Parameters) || value.is_a?(Hash)
        # If any non-integer keys
        if value.keys.find {|k, _| k =~ /\D/ }
          repair_nested_params(value)
        else
          obj[key] = value.values
          value.values.each {|h| repair_nested_params(h) }
        end
      end
    end
  end

  # convert empty string value to nil
  def convert_params(obj)
    if obj.is_a?(Array)
      obj.map! do |array_element|
        convert_params(array_element)
      end
    elsif obj.is_a?(Hash) || obj.is_a?(ActionController::Parameters)
      obj.each do |k, v|
        convert_params(v) if v.is_a?(Array)

        obj[k] = nil if v.blank?
      end
      obj
    end
  end
end
