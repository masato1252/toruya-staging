class UpdateShop < ActiveInteraction::Base
  object :shop, class: Shop
  boolean :holiday_working, default: false

  def execute
    unless shop.update(holiday_working: holiday_working)
      errors.merge!(shop.errors)
    end
  end
end

