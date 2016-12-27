class Options::MenuOption < Option
  attr_reader :id, :name, :min_staffs_number, :available_seat

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @min_staffs_number = attributes[:min_staffs_number]
    @available_seat = attributes[:available_seat]
    super
  end
end
