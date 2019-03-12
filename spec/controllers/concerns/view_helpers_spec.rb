require "rails_helper"

class FakesController < ApplicationController
  include ViewHelpers
end

RSpec.describe FakesController do
  before do
    allow(subject).to receive(:current_user).and_return(current_user)
    allow(subject).to receive(:super_user).and_return(super_user)
  end

  let(:staff) { FactoryBot.create(:staff) }
  let(:current_user) { staff.staff_account.user }
  let(:super_user) { staff.staff_account.owner }
  let(:shop) { staff.shops.take  }

  describe "#working_shop_options" do
    # current_user staff's own shop
    let!(:current_user_staff_in_self_own_shop) { FactoryBot.create(:staff, user: current_user, mapping_user: current_user) }

    it "returns options without user own personally" do
      options = subject.working_shop_options

      expect(options.length).to eq(1)
      expect(options.first.attrs).to eq(
        Option.new(
          shop: shop,
          shop_id: shop.id,
          staff: staff,
          staff_id: staff.id,
          owner: super_user,
          shop_staff: staff.shop_staffs.first
        ).attrs
      )
    end

    context "when options includes user owne" do
      it "returns options includes user own personally" do
        options = subject.working_shop_options(include_user_own: true)

        expect(options.length).to eq(2)
      end
    end

    context "when options is manager_or_owner_required" do
      it "returns expected options" do
        options = subject.working_shop_options(manager_above_level_required: true)

        expect(options).to be_empty
      end

      it "returns current user self own option" do
        options = subject.working_shop_options(include_user_own: true, manager_above_level_required: true)

        current_user_shop = current_user_staff_in_self_own_shop.shops.first

        expect(options.length).to eq(1)
        expect(options.first.attrs).to eq(
          Option.new(
            shop: current_user_shop,
            shop_id: current_user_shop.id,
            staff: current_user_staff_in_self_own_shop,
            staff_id: current_user_staff_in_self_own_shop.id,
            owner: current_user,
            shop_staff: current_user_staff_in_self_own_shop.shop_staffs.first
          ).attrs
        )
      end
    end
  end
end
