require 'rails_helper'

RSpec.describe Ability do
  let(:current_user) { FactoryBot.create(:user) }
  let(:super_user) { current_user }
  let(:ability) { described_class.new(current_user, super_user) }

  RSpec.shared_examples "admin management" do |member_level, action, ability_name, permission|
    it "#{member_level} member #{permission ? "can" : "cannot" } #{action} #{ability_name}" do
      allow(super_user).to receive(:member_level).and_return(member_level)

      expect(ability.can?(action, ability_name)).to eq(permission)
    end
  end

  describe "can?" do
    context "admin level" do
      {
        "free"    => [
          {
            action: :manage,
            ability_name: :preset_filter,
            permission: false
          },
          {
            action: :manage,
            ability_name: :saved_filter,
            permission: false
          },
          {
            action: :create,
            ability_name: Staff,
            permission: false
          },
          {
            action: :read,
            ability_name: :shop_dashboard,
            permission: false
          },
          {
            action: :read,
            ability_name: :filter,
            permission: false
          },
        ],
        "trial"   => [
          {
            action: :manage,
            ability_name: :preset_filter,
            permission: true
          },
          {
            action: :manage,
            ability_name: :saved_filter,
            permission: true
          },
          {
            action: :create,
            ability_name: Staff,
            permission: false
          },
          {
            action: :read,
            ability_name: :shop_dashboard,
            permission: true
          },
          {
            action: :read,
            ability_name: :filter,
            permission: true
          },
        ],
        "basic"   => [
          {
            action: :manage,
            ability_name: :preset_filter,
            permission: true
          },
          {
            action: :manage,
            ability_name: :saved_filter,
            permission: false
          },
          {
            action: :create,
            ability_name: Staff,
            permission: false
          },
          {
            action: :read,
            ability_name: :shop_dashboard,
            permission: false
          },
          {
            action: :read,
            ability_name: :filter,
            permission: true
          },
        ],
        "premium" => [
          {
            action: :manage,
            ability_name: :preset_filter,
            permission: true
          },
          {
            action: :manage,
            ability_name: :saved_filter,
            permission: true
          },
          {
            action: :create,
            ability_name: Staff,
            permission: true
          },
          {
            action: :read,
            ability_name: :shop_dashboard,
            permission: true
          },
          {
            action: :read,
            ability_name: :filter,
            permission: true
          },
        ],
      }.each do |member_level, permissions|
        permissions.each do |permission|
          it_behaves_like "admin management", member_level, permission[:action], permission[:ability_name], permission[:permission]
        end
      end

      context "create Shop" do
        context "when users don't have any shop" do
          it_behaves_like "admin management", "free", :create, Shop, true
          it_behaves_like "admin management", "trial", :create, Shop, true
          it_behaves_like "admin management", "basic", :create, Shop, true
          it_behaves_like "admin management", "premium", :create, Shop, true
        end

        context "when users already have shop" do
          before { FactoryBot.create(:shop, user: current_user) }

          it_behaves_like "admin management", "free", :create, Shop, false
          it_behaves_like "admin management", "trial", :create, Shop, false
          it_behaves_like "admin management", "basic", :create, Shop, false
          it_behaves_like "admin management", "premium", :create, Shop, true
        end
      end

      context "create Reservation" do
        context "when users don't have any reservation" do
          it_behaves_like "admin management", "free", :create, Reservation, true
          it_behaves_like "admin management", "trial", :create, Reservation, true
          it_behaves_like "admin management", "basic", :create, Reservation, true
          it_behaves_like "admin management", "premium", :create, Reservation, true
        end

        context "when users already have shop" do
          context "when over daily reservation limit" do
            before do
              stub_const("Ability::RESERVATION_DAILY_LIMIT", 1)
              shop = FactoryBot.create(:shop, user: current_user)
              FactoryBot.create(:reservation, shop: shop)
            end

            it_behaves_like "admin management", "free", :create, Reservation, false
            it_behaves_like "admin management", "trial", :create, Reservation, false
            it_behaves_like "admin management", "basic", :create, Reservation, false
            it_behaves_like "admin management", "premium", :create, Reservation, true
          end

          context "when over total reservation limit" do
            before do
              stub_const("Ability::TOTAL_RESERVATIONS_LIMITS", {
                "free"  => 1,
                "trial" => 1,
                "basic" => 1
              })
              shop = FactoryBot.create(:shop, user: current_user)
              FactoryBot.create(:reservation, shop: shop)
            end

            it_behaves_like "admin management", "free", :create, Reservation, false
            it_behaves_like "admin management", "trial", :create, Reservation, false
            it_behaves_like "admin management", "basic", :create, Reservation, false
            it_behaves_like "admin management", "premium", :create, Reservation, true
          end
        end
      end
    end
  end
end
