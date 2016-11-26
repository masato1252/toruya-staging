class MenuStaff
  attr_accessor :id, :name, :staff_id, :menu_id, :max_customers, :checked, :attributes

  def initialize(attributes = {})
    @attributes = attributes
  end
end
