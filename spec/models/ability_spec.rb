require 'rails_helper'

RSpec.describe Ability do
  let(:current_user) { FactoryBot.create(:user) }
  let(:super_user) { current_user }
  let(:shop) { nil }
  let(:ability) { described_class.new(current_user, super_user, shop) }

  RSpec.shared_examples "permission management" do |member_level, action, ability_name, permission|
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
          it_behaves_like "permission management", member_level, permission[:action], permission[:ability_name], permission[:permission]
        end
      end

      context "create Shop" do
        context "when users don't have any shop" do
          it_behaves_like "permission management", "free", :create, Shop, true
          it_behaves_like "permission management", "trial", :create, Shop, true
          it_behaves_like "permission management", "basic", :create, Shop, true
          it_behaves_like "permission management", "premium", :create, Shop, true
        end

        context "when users already have shop" do
          before { FactoryBot.create(:shop, user: current_user) }

          it_behaves_like "permission management", "free", :create, Shop, false
          it_behaves_like "permission management", "trial", :create, Shop, false
          it_behaves_like "permission management", "basic", :create, Shop, false
          it_behaves_like "permission management", "premium", :create, Shop, true
        end
      end

      context "create Reservation" do
        context "when users don't have any reservation" do
          # it_behaves_like "permission management", "free", :create, Reservation, true
          # it_behaves_like "permission management", "trial", :create, Reservation, true
          # it_behaves_like "permission management", "basic", :create, Reservation, true
          # it_behaves_like "permission management", "premium", :create, Reservation, true
          it_behaves_like "permission management", "free", :create, :daily_reservations, true
          it_behaves_like "permission management", "trial", :create, :daily_reservations, true
          it_behaves_like "permission management", "basic", :create, :daily_reservations, true
          it_behaves_like "permission management", "premium", :create, :daily_reservations, true
          it_behaves_like "permission management", "free", :create, :total_reservations, true
          it_behaves_like "permission management", "trial", :create, :total_reservations, true
          it_behaves_like "permission management", "basic", :create, :total_reservations, true
          it_behaves_like "permission management", "premium", :create, :total_reservations, true
        end

        context "when users already have shop" do
          context "when over daily reservation limit" do
            before do
              stub_const("Reservations::DailyLimit::RESERVATION_DAILY_LIMIT", 1)
              shop = FactoryBot.create(:shop, user: current_user)
              FactoryBot.create(:reservation, shop: shop)
            end

            # it_behaves_like "permission management", "free", :create, Reservation, false
            # it_behaves_like "permission management", "trial", :create, Reservation, false
            # it_behaves_like "permission management", "basic", :create, Reservation, false
            # it_behaves_like "permission management", "premium", :create, Reservation, true
          end

          context "when over total reservation limit" do
            before do
              stub_const("Reservations::TotalLimit::TOTAL_RESERVATIONS_LIMITS", {
                "free"  => 1,
                "trial" => 1,
                "basic" => 1
              })
              shop = FactoryBot.create(:shop, user: current_user)
              FactoryBot.create(:reservation, shop: shop)
            end

            # it_behaves_like "permission management", "free", :create, Reservation, false
            # it_behaves_like "permission management", "trial", :create, Reservation, false
            # it_behaves_like "permission management", "basic", :create, Reservation, false
            # it_behaves_like "permission management", "premium", :create, Reservation, true
          end
        end
      end
    end

    context "staff level" do
      let(:staff) { FactoryBot.create(:staff, level: :staff) }
      let(:staff_account) { staff.staff_account }
      let(:current_user) { staff_account.user }
      let(:super_user) { staff_account.owner }
      let(:shop) { staff.shops.first }

      context "create Reservation" do
        context "when users don't have any reservation" do
          # it_behaves_like "permission management", "free", :create, Reservation, true
          # it_behaves_like "permission management", "trial", :create, Reservation, true
          # it_behaves_like "permission management", "basic", :create, Reservation, true
          # it_behaves_like "permission management", "premium", :create, Reservation, true
          it_behaves_like "permission management", "free", :create, :daily_reservations, true
          it_behaves_like "permission management", "trial", :create, :daily_reservations, true
          it_behaves_like "permission management", "basic", :create, :daily_reservations, true
          it_behaves_like "permission management", "premium", :create, :daily_reservations, true
          it_behaves_like "permission management", "free", :create, :total_reservations, true
          it_behaves_like "permission management", "trial", :create, :total_reservations, true
          it_behaves_like "permission management", "basic", :create, :total_reservations, true
          it_behaves_like "permission management", "premium", :create, :total_reservations, true
        end
      end

      context "manage shop_reservations" do
        let!(:shop1) { FactoryBot.create(:shop, user: super_user) }
        let!(:shop2) { FactoryBot.create(:shop, user: super_user) }

        context "when super_user is premium member" do
          before { allow(super_user).to receive(:member_level).and_return("premium") }

          it "can manage all shop reservations" do
            expect(ability.can?(:manage_shop_reservations, shop1)).to eq(true)
            expect(ability.can?(:manage_shop_reservations, shop2)).to eq(true)
          end
        end

        [
          "basic", "trial", "free"
        ].each do |member_level|
          context "when super_user is #{member_level} member" do
            before { allow(super_user).to receive(:member_level).and_return(member_level) }

            it "can manage only one shop reservations" do
              expect(ability.can?(:manage_shop_reservations, shop)).to eq(true)
              expect(ability.can?(:manage_shop_reservations, shop1)).to eq(false)
              expect(ability.can?(:manage_shop_reservations, shop2)).to eq(false)
            end
          end
        end
      end
    end

    context "edit reservation" do
      let(:super_user) { FactoryBot.create(:user) }
      let(:current_user) { super_user }
      before { allow(super_user).to receive(:premium_member?).and_return(is_premium_member) }
      let!(:reservation) { FactoryBot.create(:reservation, shop: shop, staff_ids: staff_ids, start_time: reservation_time) }
      let(:shop) { FactoryBot.create(:shop, user: super_user) }
      let(:staff) { FactoryBot.create(:staff, user: super_user) }
      let(:staff_ids) { [staff.id] }
      let(:reservation_time) { Time.now }

      context "when user is an owner" do
        context "when user is premium member" do
          let(:is_premium_member) { true }

          it "returns true" do
            expect(ability.can?(:edit, reservation)).to eq(true)
          end
        end

        context "when user is NOT premium member" do
          let(:is_premium_member) { false }

          context "when reservation is not under valid shop" do
            before { allow(super_user).to receive(:valid_shop_ids).and_return([]) }

            it "returns false" do
              expect(ability.can?(:edit, reservation)).to eq(false)
            end
          end

          context "when reservation is under valid shop" do
            context "when reservation has no staff" do
              let(:menu) { FactoryBot.create(:menu, :no_manpower, shop: shop) }
              let!(:reservation) { FactoryBot.create(:reservation, menu: menu, shop: shop, staff_ids: staff_ids, start_time: reservation_time) }
              let(:staff_ids) { []  }

              it "returns true" do
                expect(ability.can?(:edit, reservation)).to eq(true)
              end
            end

            context "when reservation has one staff" do
              context "when staff is owner self" do
                let(:user) { FactoryBot.create(:user) }
                let(:staff_account) { FactoryBot.create(:staff_account, owner: user, user: user) }
                let(:current_user) { staff_account.owner }
                let(:super_user) { current_user }
                let(:staff_ids) { staff_account.staff_id }

                it "returns true" do
                  expect(ability.can?(:edit, reservation)).to eq(true)
                end
              end

              context "when staff is not owner self" do
                let(:staff_ids) { FactoryBot.create(:staff).id  }

                it "returns false" do
                  expect(ability.can?(:edit, reservation)).to eq(false)
                end
              end
            end

            context "when reservation has multiple staffs" do
              let(:staff_ids) { [FactoryBot.create(:staff).id, FactoryBot.create(:staff).id]  }

              context "when action is edit" do
                it "returns false" do
                  expect(ability.can?(:edit, reservation)).to eq(false)
                end
              end
            end
          end
        end
      end

      context "when user is NOT owner" do
        let(:staff_account) { staff.staff_account }
        let(:current_user) { staff_account.user }
        let(:shop) { staff.shops.first }

        context "when super user is premium member" do
          let(:is_premium_member) { true }

          it "returns true" do
            expect(ability.can?(:edit, reservation)).to eq(true)
          end
        end

        context "when user is NOT premium member" do
          let(:is_premium_member) { false }

          it "returns false" do
            expect(ability.can?(:edit, reservation)).to eq(false)
          end
        end
      end
    end

    context "see reservation" do
      context "when user is owner in reservation's shop" do
        let(:shop) { FactoryBot.create(:shop, user: super_user) }
        let!(:reservation) { FactoryBot.create(:reservation, shop: shop) }

        it "returns true" do
          expect(ability.can?(:see, reservation)).to eq(true)
        end
      end

      context "when user is manager in reservation's shop" do
        let(:staff) { FactoryBot.create(:staff, :manager) }
        let(:staff_account) { staff.staff_account }
        let(:current_user) { staff_account.user }
        let(:super_user) { staff_account.owner }
        let(:shop) { staff.shops.first }
        let!(:reservation) { FactoryBot.create(:reservation, shop: shop) }

        it "returns true" do
          expect(ability.can?(:see, reservation)).to eq(true)
        end
      end

      context "when user is staff in reservation's shop" do
        let(:staff_account) { FactoryBot.create(:staff_account) }
        let(:current_user) { staff_account.user }
        let(:super_user) { staff_account.owner }
        let(:shop) { staff_account.staff.shops.first }
        let!(:reservation) { FactoryBot.create(:reservation, shop: shop, staff_ids: staff_ids) }

        context "when staff is responsible for this reservation" do
          let(:staff_ids) { staff_account.staff_id }

          it "returns true" do
            expect(ability.can?(:see, reservation)).to eq(true)
          end
        end

        context "when staff is not responsible for this reservation" do
          let(:staff_ids) { FactoryBot.create(:staff).id }

          it "returns false" do
            expect(ability.can?(:see, reservation)).to eq(false)
          end
        end
      end
    end

    context "edit Staff" do
      let(:staff) { FactoryBot.create(:staff) }
      let(:staff_account) { staff.staff_account }
      let(:super_user) { staff_account.owner }
      let(:current_user) { staff_account.user }
      let(:shop) { staff.shops.first }

      context "when super user is premium member" do
        before { allow(super_user).to receive(:premium_member?).and_return(true) }

        context "user is admin level" do
          let(:current_user) { staff_account.owner }

          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(true)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(true)
            end
          end

          context "when staff is owned by other user" do
            let(:other_staff) { FactoryBot.create(:staff) }

            it "returns true" do
              expect(ability.can?(:edit, other_staff)).to eq(false)
            end
          end
        end

        context "user is manager level" do
          let(:staff) { FactoryBot.create(:staff, :manager) }

          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(true)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(true)
            end
          end
        end

        context "user is staff level" do
          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(true)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(false)
            end
          end
        end
      end

      context "when super user is NOT premium member" do
        before { allow(super_user).to receive(:premium_member?).and_return(false) }

        context "user is admin level" do
          let(:staff) { FactoryBot.create(:staff, :owner) }
          let(:current_user) { staff_account.owner }

          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(true)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(false)
            end
          end

          context "when staff is owned by other user" do
            let(:other_staff) { FactoryBot.create(:staff) }

            it "returns true" do
              expect(ability.can?(:edit, other_staff)).to eq(false)
            end
          end
        end

        context "user is manager level" do
          let(:staff) { FactoryBot.create(:staff, :manager) }

          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(false)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(false)
            end
          end
        end

        context "user is staff level" do
          context "when staff is userself" do
            it "returns true" do
              expect(ability.can?(:edit, staff)).to eq(false)
            end
          end

          context "when staff is NOT userself" do
            let(:staff2) { FactoryBot.create(:staff, user: super_user) }

            it "returns true" do
              expect(ability.can?(:edit, staff2)).to eq(false)
            end
          end
        end
      end
    end

    context "read customers_dashboard" do
      context "user is admin level" do
        it "returns true" do
          expect(ability.can?(:read, :customers_dashboard)).to eq(true)
        end
      end

      context "when super_user is premium member" do
        before { allow(super_user).to receive(:premium_member?).and_return(true) }

        let(:staff) { FactoryBot.create(:staff) }
        let(:staff_account) { staff.staff_account }
        let(:current_user) { staff_account.user }
        let(:super_user) { staff_account.owner }

        it "returns false" do
          expect(ability.can?(:read, :customers_dashboard)).to eq(false)
        end

        context "when staff had contact groups" do
          let(:staff) { FactoryBot.create(:staff, :with_contact_groups) }

          it "returns true" do
            expect(ability.can?(:read, :customers_dashboard)).to eq(true)
          end
        end
      end
    end
  end
end
