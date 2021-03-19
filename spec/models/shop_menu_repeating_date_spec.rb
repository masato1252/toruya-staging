# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Shop, type: :model do
  let(:shop) { FactoryBot.create(:shop) }
  let(:menu) { FactoryBot.create(:menu, shop: shop) }
  let(:menu_rule) { FactoryBot.create(:menu_reservation_setting_rule, menu: menu, repeats: 3) }
  let(:now) { Time.zone.now }

  it "check available repeating dates" do
    repeating_dates = FactoryBot.create(:shop_menu_repeating_date, shop: shop, menu: menu,
                                         dates: [Time.zone.now.to_date, Time.zone.now.tomorrow.to_date])

    scope = ShopMenuRepeatingDate.where(shop: shop, menu: menu)

    expect(scope.where("? = ANY(dates)", now.to_date)).to be_exist
    expect(scope.where("? = ANY(dates)", now.tomorrow.to_date)).to be_exist
    expect(scope.where("? = ANY(dates)", now.yesterday.to_date)).not_to be_exist
  end
end
