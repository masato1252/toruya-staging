# rubocop:disable Style/FrozenStringLiteralComment
# Couldn't use magic comment to freeze string here, the CSV.generate("\uFEFF") would change original string

module CsvGenerator
  def self.perform(option = {}, &block)
    CSV.generate(bom, { headers: true, row_sep: "\r\n" }.merge(option), &block)
  end

  # BOM couldn't freeze because CSV.generate would change the original string
  # \uFEFF used to handle excel encoding issue
  def self.bom
    "\uFEFF"
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
