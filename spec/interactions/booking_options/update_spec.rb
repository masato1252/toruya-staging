# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingOptions::Update do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user) }
  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:args) do
    {
      booking_option: booking_option,
      update_attribute: update_attribute,
      attrs: {}
    }
  end
  let(:outcome) { described_class.run(args) }


  RSpec.shared_examples "updates booking option normal attribute" do |attribute, value|
    let(:update_attribute) { attribute }
    before { args[:attrs][attribute] = value }

    it "updates #{attribute} to #{value}" do
      outcome

      expect(booking_option.public_send(attribute)).to eq(value)
    end
  end

  describe "#execute" do
    context "update_attribute is name" do
      it_behaves_like "updates booking option normal attribute", "name", "foo"
    end

    context "update_attribute is display_name" do
      it_behaves_like "updates booking option normal attribute", "display_name", "foo"
    end

    context "update_attribute is menu_restrict_order" do
      it_behaves_like "updates booking option normal attribute", "menu_restrict_order", true
      it_behaves_like "updates booking option normal attribute", "menu_restrict_order", false
    end

    context "update_attribute is memo" do
      it_behaves_like "updates booking option normal attribute", "memo", "foo"

      context "when booking_option is line_keyword_booking_option" do
        let(:booking_page) { FactoryBot.create(:booking_page, rich_menu_only: true, user: user) }
        let(:update_attribute) { "memo" }
        before do
          user.user_setting.update(line_keyword_booking_option_ids: [booking_option.id])
          booking_page.booking_options << booking_option
          args[:attrs][:memo] = "foo"
        end

        it "updates booking_page name and greeting" do
          outcome

          booking_page.reload
          expect(booking_page.name).to eq(booking_option.display_name.presence || booking_option.name)
          expect(booking_page.greeting).to eq("foo")
        end
      end
    end

    context "update_attribute is option_type" do
      it_behaves_like "updates booking option normal attribute", "option_type", "primary"
      it_behaves_like "updates booking option normal attribute", "option_type", "secondary"

      context "when changing from primary to secondary" do
        let(:update_attribute) { "option_type" }
        before do
          booking_option.update!(option_type: "primary")
          args[:attrs][:option_type] = "secondary"
        end

        it "updates option_type successfully" do
          outcome

          expect(booking_option.reload.option_type).to eq("secondary")
          expect(booking_option.secondary?).to be true
        end
      end

      context "when changing from secondary to primary" do
        let(:update_attribute) { "option_type" }
        before do
          booking_option.update!(option_type: "secondary")
          args[:attrs][:option_type] = "primary"
        end

        it "updates option_type successfully" do
          outcome

          expect(booking_option.reload.option_type).to eq("primary")
          expect(booking_option.primary?).to be true
        end
      end
    end

    context "update_attribute is new_pure_menu" do
      let!(:staff_account) { FactoryBot.create(:staff_account, owner: user, user: user) }
      let(:update_attribute) { "new_pure_menu" }
      before do
        args[:attrs][:new_menu_name] = "foo"
        args[:attrs][:new_menu_minutes] = 100
        args[:attrs][:new_menu_online_state] = true
      end

      it "creates a new booking_option_menus" do
        expect {
          outcome
        }.to change {
          booking_option.booking_option_menus.count
        }.and change {
          Menu.count
        }

        last_booking_menu = booking_option.booking_option_menus.last
        new_menu = Menu.last

        expect(last_booking_menu.menu.name).to eq("foo")
        expect(last_booking_menu.required_time).to eq(100)
        expect(last_booking_menu.priority).to eq(booking_option.booking_option_menus.count - 1)
        expect(new_menu.name).to eq("foo")
        expect(new_menu.minutes).to eq(100)
        expect(new_menu.online).to eq(true)
      end
    end

    context "update_attribute is new_menu" do
      let(:update_attribute) { "new_menu" }
      let(:new_menu) { FactoryBot.create(:menu, user: user) }
      before do
        args[:attrs][:new_menu_id] = new_menu.id
        args[:attrs][:new_menu_required_time] = 200
      end

      it "creates a new booking_option_menus" do
        outcome

        last_booking_menu = booking_option.booking_option_menus.last

        expect(last_booking_menu.menu_id).to eq(new_menu.id)
        expect(last_booking_menu.required_time).to eq(200)
        expect(last_booking_menu.priority).to eq(booking_option.booking_option_menus.count - 1)
      end
    end

    context "update_attribute is start_at" do
      let(:update_attribute) { "start_at" }
      before do
        args[:attrs][:start_at_date_part] = "2020-12-01"
        args[:attrs][:start_at_time_part] = "16:00"
      end

      it "updates start_at" do
        outcome

        expect(booking_option.start_at).to eq(Time.zone.local(2020, 12, 1, 16, 00))
      end
    end

    context "update_attribute is end_at" do
      let(:update_attribute) { "end_at" }
      before do
        args[:attrs][:end_at_date_part] = "2020-12-01"
        args[:attrs][:end_at_time_part] = "16:00"
      end

      it "updates end_at" do
        outcome

        expect(booking_option.end_at).to eq(Time.zone.local(2020, 12, 1, 16, 00))
      end
    end

    context "update_attribute is price" do
      let(:update_attribute) { "price" }
      before do
        args[:attrs][:amount_cents] = 100
        args[:attrs][:amount_currency] = "JPY"
        args[:attrs][:tax_include] = true
        args[:attrs][:ticket_quota] = 3
      end

      it "updates price" do
        outcome

        expect(booking_option.amount).to eq(Money.new(100, "JPY"))
        expect(booking_option.tax_include).to eq(true)
        expect(booking_option.ticket_quota).to eq(3)
      end
    end

    context "update_attribute is menus_priority" do
      let(:update_attribute) { "menus_priority" }
      let(:booking_option) { FactoryBot.create(:booking_option, :multiple_menus, user: user) }
      let(:new_menu_ids_order) { booking_option.menu_ids.reverse }

      before do
        args[:attrs][:sorted_menus_ids] = new_menu_ids_order
      end

      it "updates menus order" do
        outcome

        expect(booking_option.booking_option_menus.order("priority").pluck(:menu_id)).to eq(new_menu_ids_order)
      end
    end

    context "update_attribute is menu_required_time" do
      let(:update_attribute) { "menu_required_time" }

      before do
        args[:attrs][:menu_id] = booking_option.menus.first.id
        args[:attrs][:menu_required_time] = 200
      end

      it "updates menu required_time" do
        expect {
          outcome
        }.to change {
          booking_option.reload.minutes
        }.to(200)

        booking_option_menu = booking_option.booking_option_menus.first

        expect(booking_option_menu.menu_id).to eq(booking_option.menus.first.id)
        expect(booking_option_menu.required_time).to eq(200)
        expect(booking_option.minutes).to eq(200)
      end

      context "when booking option only has one menu" do
        let(:booking_option) { FactoryBot.create(:booking_option, :single_menu, user: user) }

        it "updates menu minutes" do
          expect {
            outcome
          }.to change {
            booking_option.menus.first.minutes
          }.to(200)

          expect(booking_option.reload.minutes).to eq(200)
        end
      end

      context "when booking option has multiple menus" do
        let(:booking_option) { FactoryBot.create(:booking_option, :multiple_menus, user: user) }

        it "does NOT update menu minutes" do
          expect {
            outcome
          }.to not_change {
            booking_option.menus.first.minutes
          }
        end
      end
    end
  end
end