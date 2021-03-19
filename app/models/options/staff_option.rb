# frozen_string_literal: true

class Options::StaffOption < Option
  attr_reader :id, :name, :handable_customers

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @handable_customers  = attributes[:handable_customers]
    super
  end
end
