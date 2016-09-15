def create(*args)
  FactoryGirl.create(*args) do |obj|
    yield obj if block_given?
  end
end

create(:user, email: "superadmin@email.com", password: "password123", confirmed_at: Time.now) do |user|
  create(:shop, user: user) do |shop|
    menu = create(:menu, user: user, max_seat_number: nil) do |menu|
      create(:reservation_setting, user: user) do |setting|
        create(:reservation_setting_menu, reservation_setting: setting, menu: menu)
      end
      create(:shop_menu, shop: shop, menu: menu)
    end

    lecture_menu = create(:menu, :lecture, user: user) do |lecture_menu|
      create(:reservation_setting, user: user) do |setting|
        create(:reservation_setting_menu, reservation_setting: setting, menu: lecture_menu)
      end
      create(:shop_menu, shop: shop, menu: lecture_menu)
    end

    create(:menu, :lecture, user: user) do |vip_menu|
      create(:reservation_setting, user: user) do |setting|
        create(:reservation_setting_menu, reservation_setting: setting, menu: vip_menu)
      end
    end

    create(:staff, user: user) do |staff|
      create(:shop_staff, shop: shop, staff: staff)
      create(:staff_menu, staff: staff, menu: menu, max_customers: 2)
      create(:staff_menu, staff: staff, menu: lecture_menu, max_customers: nil)
    end

    create(:staff, user: user) do |staff2|
      create(:shop_staff, shop: shop, staff: staff2)
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
