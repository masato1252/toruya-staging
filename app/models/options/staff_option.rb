class Options::StaffOption < Option
  attr_reader :id, :name, :max_customers, :occupied_customers_count

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @max_seat_number = attributes[:max_customers]
    @occupied_number = attributes[:occupied_customers_count]
    super
  end
end
