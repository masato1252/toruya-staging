class NoFullWidthValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    return if value.nil?
    return if value.chars.count == value.bytes.count

    record.errors.add(attribute, :has_full_width_characters)
  end
end

