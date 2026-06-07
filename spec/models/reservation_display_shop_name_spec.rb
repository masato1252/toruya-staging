# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reservation, "#display_shop_name" do
  let(:user) { FactoryBot.create(:user) }
  let(:shop) { user.shops.first }
  let(:reservation) do
    FactoryBot.create(
      :reservation,
      user: user,
      shop: shop,
      shop_name_snapshot: "保存済み店舗名"
    )
  end

  it "returns snapshot when present" do
    expect(reservation.display_shop_name).to eq("保存済み店舗名")
  end

  it "falls back to shop display name" do
    reservation.update!(shop_name_snapshot: nil)
    expect(reservation.display_shop_name).to eq(shop.display_name)
  end
end
