class Options::MenuOption < Option
  attr_reader :id, :name, :available_seat

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @available_seat = attributes[:available_seat]
    super
  end
end
