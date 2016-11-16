module NormalizeName
  extend ActiveSupport::Concern

  included do
    default_value_for :last_name, ""
    default_value_for :first_name, ""
    default_value_for :phonetic_last_name, ""
    default_value_for :phonetic_first_name, ""
  end

  module ClassMethods
  end

  def name
    "#{last_name} #{first_name}".presence || "#{phonetic_last_name} #{phonetic_first_name}".presence
  end
end
