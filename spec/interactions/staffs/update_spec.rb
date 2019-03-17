require "rails_helper"

RSpec.describe Staffs::Update do
  let(:staff) { FactoryBot.create(:staff) }
  let(:args) do
    {
      staff: staff,
      user_level: "admin",
      attrs: {
        first_name: "foo",
        last_name: "bar",
        phonetic_first_name: "baz",
        phonetic_last_name: "qux",
        shop_ids: [""],
        contact_group_ids: [""]
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when user_level is unexpected" do
      it "adds an error" do
        args.merge!(user_level: "foo")

        expect(outcome.errors.details[:user_level]).to include(error: :invalid)
      end
    end

    context "when staff is an owner" do
      let(:staff) { FactoryBot.create(:staff, :owner) }

      it "only changes staff's first_name, last_name, phonetic_first_name, phonetic_last_name attributes" do
        args[:attrs].merge!(
          first_name: "qux",
          last_name: "baz",
          phonetic_first_name: "bar",
          phonetic_last_name: "foo",
          shop_ids: ["", FactoryBot.create(:shop, user: staff.user).id],
          contact_group_ids: ["", FactoryBot.create(:contact_group, user: staff.user).id]
        )

        expect {
          outcome
        }.to change {
          staff.first_name
        }.and change {
          staff.last_name
        }.and change {
          staff.phonetic_first_name
        }.and change {
          staff.phonetic_last_name
        }.and not_change {
          staff.shop_ids
        }.and not_change {
          staff.contact_group_ids
        }
      end
    end

    context "when staff is an employee" do
      context "when user is an admin" do
        it "changes all attributes" do
          shop = FactoryBot.create(:shop, user: staff.user)
          contact_group = FactoryBot.create(:contact_group, user: staff.user)
          email = Faker::Internet.email

          args.merge!(
            user_level: "admin",
            attrs: {
              first_name: "qux",
              last_name: "baz",
              phonetic_first_name: "bar",
              phonetic_last_name: "foo",
              shop_ids: ["", shop.id],
              contact_group_ids: ["", contact_group.id]
            },
            staff_account_attributes: {
              email: email
            },
            shop_staff_attributes: {
              shop.id => {
                level: "manager",
                staff_full_time_permission: 1,
                staff_regular_working_day_permission: 0,
                staff_temporary_working_day_permission: 1
              }
            },
            contact_group_attributes: {
              contact_group.id => {
                contact_group_read_permission: "details_readable"
              }
            }
          )

          expect {
            outcome
          }.to change {
            staff.first_name
          }.and change {
            staff.last_name
          }.and change {
            staff.phonetic_first_name
          }.and change {
            staff.phonetic_last_name
          }.and change {
            staff.shop_ids
          }.and change {
            staff.contact_group_ids
          }

          shop_relation = staff.shop_relations.first
          staff.staff_account.reload
          expect(staff.staff_account.email).to eq(email)
          expect(shop_relation.shop_id).to eq(shop.id)
          expect(shop_relation).to be_manager_level
          expect(shop_relation.staff_full_time_permission).to eq(true)
          expect(shop_relation.staff_regular_working_day_permission).to eq(false)
          expect(shop_relation.staff_temporary_working_day_permission).to eq(true)

          contact_group_relation = staff.contact_group_relations.find_by(contact_group_id: contact_group.id)
          expect(contact_group_relation).to be_details_readable
        end
      end

      context "when user is an manager" do
        it "changes attributes except contact_group_ids" do
          shop = FactoryBot.create(:shop, user: staff.user)
          contact_group = FactoryBot.create(:contact_group, user: staff.user)
          email = Faker::Internet.email

          args.merge!(
            user_level: "manager",
            attrs: {
              first_name: "qux",
              last_name: "baz",
              phonetic_first_name: "bar",
              phonetic_last_name: "foo",
              shop_ids: ["", shop.id],
              contact_group_ids: ["", contact_group.id]
            },
            staff_account_attributes: {
              email: email
            },
            shop_staff_attributes: {
              shop.id => {
                level: "manager",
                staff_full_time_permission: 1,
                staff_regular_working_day_permission: 0,
                staff_temporary_working_day_permission: 1
              }
            },
            contact_group_attributes: {
              contact_group.id => {
                contact_group_read_permission: "details_readable"
              }
            }
          )

          expect {
            outcome
          }.to change {
            staff.first_name
          }.and change {
            staff.last_name
          }.and change {
            staff.phonetic_first_name
          }.and change {
            staff.phonetic_last_name
          }.and change {
            staff.shop_ids
          }.and not_change {
            staff.contact_group_ids
          }.and change {
            staff.staff_account.reload.email
          }

          shop_relation = staff.shop_relations.first
          staff.staff_account.reload
          expect(staff.staff_account.email).to eq(email)
          expect(shop_relation.shop_id).to eq(shop.id)
          expect(shop_relation).to be_manager_level
          expect(shop_relation.staff_full_time_permission).to eq(true)
          expect(shop_relation.staff_regular_working_day_permission).to eq(false)
          expect(shop_relation.staff_temporary_working_day_permission).to eq(true)

          contact_group_relation = staff.contact_group_relations.find_by(contact_group_id: contact_group.id)
          expect(contact_group_relation).to be_nil
        end
      end

      context "when user is a staff" do
        it "only changes first_name, last_name, phonetic_first_name, phonetic_last_name attributes" do
          shop = FactoryBot.create(:shop, user: staff.user)
          contact_group = FactoryBot.create(:contact_group, user: staff.user)
          email = Faker::Internet.email

          args.merge!(
            user_level: "staff",
            attrs: {
              first_name: "qux",
              last_name: "baz",
              phonetic_first_name: "bar",
              phonetic_last_name: "foo",
              shop_ids: ["", shop.id],
              contact_group_ids: ["", contact_group.id]
            },
            staff_account_attributes: {
              email: email
            },
            shop_staff_attributes: {
              shop.id => {
                level: "manager",
                staff_full_time_permission: 1,
                staff_regular_working_day_permission: 0,
                staff_temporary_working_day_permission: 1
              }
            },
            contact_group_attributes: {
              contact_group.id => {
                contact_group_read_permission: "details_readable"
              }
            }
          )

          expect {
            outcome
          }.to change {
            staff.first_name
          }.and change {
            staff.last_name
          }.and change {
            staff.phonetic_first_name
          }.and change {
            staff.phonetic_last_name
          }.and not_change {
            staff.shop_ids
          }.and not_change {
            staff.contact_group_ids
          }.and not_change {
            staff.staff_account.email
          }
        end
      end
    end

    context "when staff change the working shops" do
      it "cleans up previous shop business_schedules, custom_schedules" do
        shop = FactoryBot.create(:shop, user: staff.user)
        previous_shop = FactoryBot.create(:shop, user: staff.user)
        contact_group = FactoryBot.create(:contact_group, user: staff.user)
        email = Faker::Internet.email
        FactoryBot.create(:shop_staff, staff: staff, shop: previous_shop)
        FactoryBot.create(:custom_schedule, :opened, shop: previous_shop, staff: staff)
        FactoryBot.create(:business_schedule, :opened, shop: previous_shop, staff: staff)

        args.merge!(
          user_level: "manager",
          attrs: {
            shop_ids: ["", shop.id],
            contact_group_ids: ["", contact_group.id]
          },
          staff_account_attributes: {
            email: email
          },
        )

        expect(staff.custom_schedules.where(shop: previous_shop)).to be_present
        expect(staff.business_schedules.where(shop: previous_shop)).to be_present
        outcome

        expect(staff.custom_schedules.where(shop: previous_shop)).to be_blank
        expect(staff.business_schedules.where(shop: previous_shop)).to be_blank
      end
    end
  end
end
