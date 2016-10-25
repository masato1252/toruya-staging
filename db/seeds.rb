def create(*args)
  FactoryGirl.create(*args) do |obj|
    yield obj if block_given?
  end
end

create(:user, email: "superadmin@email.com", password: "password123", confirmed_at: Time.now) do |user|
  create(:shop, user: user) do |shop|
    menu = create(:menu, user: user, max_seat_number: nil, shop: shop) do |menu|
      create(:reservation_setting, user: user, menu: menu)
    end

    lecture_menu = create(:menu, :lecture, user: user, shop: shop) do |lecture_menu|
      create(:reservation_setting, user: user, menu: lecture_menu)
    end

    create(:menu, :lecture, user: user, shop: shop) do |vip_menu|
      create(:reservation_setting, user: user, menu: vip_menu)
    end

    create(:staff, shop: shop, user: user) do |staff|
      create(:staff_menu, staff: staff, menu: menu, max_customers: 2)
      create(:staff_menu, staff: staff, menu: lecture_menu, max_customers: nil)
    end

    create(:staff, shop: shop, user: user) do |staff2|
      create(:staff_menu, staff: staff2, menu: menu, max_customers: 2)
      create(:staff_menu, staff: staff2, menu: lecture_menu, max_customers: nil)
    end

    4.times do
      create(:customer, user: user)
    end

    (1..5).each do |wday|
      create(:business_schedule, shop: shop, day_of_week: wday)
    end
  end
end
