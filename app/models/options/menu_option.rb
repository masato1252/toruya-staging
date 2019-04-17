class Options::MenuOption < Option
  attr_reader :id, :name, :min_staffs_number, :available_seat, :minutes, :interval

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @min_staffs_number = attributes[:min_staffs_number]
    @available_seat = attributes[:available_seat]
    @minutes = attributes[:minutes]
    @interval = attributes[:interval]
    super
  end
end
