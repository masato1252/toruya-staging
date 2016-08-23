user = FactoryGirl.create(:user, email: "superadmin@email.com", password: "password123", confirmed_at: Time.now)
shop = FactoryGirl.create(:shop, user: user)
menu = FactoryGirl.create(:menu, shop: shop, max_seat_number: nil)
lecture_menu = FactoryGirl.create(:menu, :lecture, shop: shop)
staff = FactoryGirl.create(:staff, shop: shop)
staff2 = FactoryGirl.create(:staff, shop: shop)
FactoryGirl.create(:reservation_setting, menu: menu)
FactoryGirl.create(:reservation_setting, menu: lecture_menu)
FactoryGirl.create(:staff_menu, staff: staff, menu: menu, max_customers: 2)
FactoryGirl.create(:staff_menu, staff: staff2, menu: menu, max_customers: 2)
FactoryGirl.create(:staff_menu, staff: staff, menu: lecture_menu, max_customers: nil)
FactoryGirl.create(:staff_menu, staff: staff2, menu: lecture_menu, max_customers: nil)

4.times do
  FactoryGirl.create(:customer, shop: shop)
end

(1..5).each do |wday|
  FactoryGirl.create(:business_schedule, shop: shop, day_of_week: wday)
end

