# frozen_string_literal: true

class Options::MenuOption < Option
  attr_reader :id, :name, :min_staffs_number, :available_seat, :minutes, :interval, :shop_ids, :online

  def initialize(attributes = {})
    @id = attributes[:id]
    @name = attributes[:name]
    @min_staffs_number = attributes[:min_staffs_number]
    @available_seat = attributes[:available_seat]
    @minutes = attributes[:minutes]
    @interval = attributes[:interval]
    @shop_ids = attributes[:shop_ids]
    @online = attributes[:online]
    super
  end
end
