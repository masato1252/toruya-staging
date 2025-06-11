# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingPages::Update do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:args) do
    {
      booking_page: booking_page,
      update_attribute: update_attribute,
      attrs: {}
    }
  end
  let(:outcome) { described_class.run(args) }

  RSpec.shared_examples "updates booking page normal attribute" do |attribute, value|
    let(:update_attribute) { attribute }
    before { args[:attrs][attribute] = value }

    it "updates #{attribute} to #{value}" do
      outcome

      expect(booking_page.public_send(attribute)).to eq(value)
    end
  end

  describe "#execute" do
    context "update_attribute is name" do
      it_behaves_like "updates booking page normal attribute", "name", "foo"
    end

    context "update_attribute is title" do
      it_behaves_like "updates booking page normal attribute", "title", "foo"
    end

    context "update_attribute is draft" do
      it_behaves_like "updates booking page normal attribute", "draft", true
      it_behaves_like "updates booking page normal attribute", "draft", false
    end

    context "update_attribute is line_sharing" do
      it_behaves_like "updates booking page normal attribute", "line_sharing", true
      it_behaves_like "updates booking page normal attribute", "line_sharing", false

      let(:update_attribute) { "line_sharing" }
      context "when line sharing is true" do
        before { args[:attrs]["line_sharing"] = true }

        it "updates user line_keyword_booking_page_ids" do
          outcome

          expect(user.reload.line_keyword_booking_page_ids).to include(booking_page.id.to_s)
        end
      end
      context "when line sharing is true" do
        before do
          args[:attrs]["line_sharing"] = false
          user.user_setting.update(line_keyword_booking_page_ids: [booking_page.id])
        end


        it "updates user line_keyword_booking_page_ids" do
          expect(user.reload.line_keyword_booking_page_ids).to include(booking_page.id.to_s)
          outcome

          expect(user.reload.line_keyword_booking_page_ids).not_to include(booking_page.id.to_s)
        end
      end
    end

    context "update_attribute is greeting" do
      it_behaves_like "updates booking page normal attribute", "greeting", "foo"
    end

    context "update_attribute is note" do
      it_behaves_like "updates booking page normal attribute", "note", "foo"
    end

    context "update_attribute is booking_time" do
      let(:update_attribute) { "booking_time" }

      context "when updating interval" do
        before do
          args[:attrs][:interval] = 60
          args[:attrs][:booking_start_times] = []
        end

        it "updates interval" do
          outcome

          expect(booking_page.interval).to eq(60)
        end
      end

      context "when updating booking_start_times" do
        before do
          args[:attrs][:booking_start_times] = [{ start_time: "10:00"}, { start_time: "13:00" } ]
        end

        it "updates specific_booking_start_times" do
          outcome

          expect(booking_page.specific_booking_start_times).to eq(["10:00", "13:00"])
        end
      end
    end

    context "when update_attribute is booking_available_period" do
      let(:update_attribute) { "booking_available_period" }

      context "when updating booking_limit_day & bookable_restriction_months" do
        before do
          args[:attrs][:booking_limit_day] = 3
          args[:attrs][:bookable_restriction_months] = 2
        end

        it "updates booking_limit_day & bookable_restriction_months" do
          outcome

          expect(booking_page.booking_limit_day).to eq(3)
          expect(booking_page.bookable_restriction_months).to eq(2)
        end
      end
    end

    context "update_attribute is overbooking_restriction" do
      it_behaves_like "updates booking page normal attribute", "overbooking_restriction", true
      it_behaves_like "updates booking page normal attribute", "overbooking_restriction", false
    end

    context "update_attribute is shop_id" do
      let(:new_shop) { FactoryBot.create(:shop, user: user) }
      let(:update_attribute) { "shop_id" }
      before do
        args[:attrs][:shop_id] = new_shop.id
      end

      it "updates shop_id" do
        outcome

        expect(booking_page.shop_id).to eq(new_shop.id)
      end

      context "when there is some booking_options, new shop doesn't support" do
        let!(:booking_option) { FactoryBot.create(:booking_option, booking_pages: [booking_page]) }

        it "adds a error" do
          expect(outcome.errors.details[:attrs].first[:error]).to eq(:unavailable_booking_option_exists)
        end
      end
    end

    context "update_attribute is new_option" do
      let(:update_attribute) { "new_option" }
      let(:new_booking_option) { FactoryBot.create(:booking_option, user: user) }
      before do
        args[:attrs][:new_option_id] = new_booking_option.id
      end

      it "creates a new booking_page_option" do
        outcome

        last_booking_option = booking_page.booking_page_options.last

        expect(last_booking_option.booking_option_id).to eq(new_booking_option.id)
      end

      context "when booking_page payment_option is online" do
        before do
          booking_page.update(payment_option: "online")
        end

        it "updates online_payment_enabled to true" do
          outcome

          expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(true)
        end
      end

      context "when booking_page payment_option is offline" do
        before do
          booking_page.update(payment_option: "offline")
        end

        it "updates online_payment_enabled to false" do
          outcome

          expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(false)
        end
      end

      context "when booking_page payment_option is custom" do
        before do
          booking_page.update(payment_option: "custom")
        end

        it "updates online_payment_enabled to false" do
          outcome

          expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(false)
        end
      end
    end

    context "update_attribute is new_option_menu" do
      let(:update_attribute) { "new_option_menu" }
      let!(:staff_account) { FactoryBot.create(:staff_account, owner: user, user: user) }

      context "when adding a exiting menu" do
        before do
          menu = FactoryBot.create(:menu, user: user)
          args[:attrs][:new_menu_id] = menu.id
          args[:attrs][:new_menu_required_time] = 123
          args[:attrs][:new_menu_price] = 456
        end

        it "creates a new booking_page_option, booking_option_menu and NOT new menu" do
          expect {
            outcome
          }.to change {
            BookingOption.count
          }.and change {
            BookingPageOption.count
          }.and change {
            BookingOptionMenu.count
          }.and not_change {
            Menu.count
          }

          expect(BookingOption.last.amount_cents).to eq(456)
          expect(BookingOption.last.minutes).to eq(123)
          expect(BookingOptionMenu.last.required_time).to eq(123)
        end

        context "with option_type specified" do
          context "when option_type is secondary" do
            before do
              args[:attrs][:option_type] = "secondary"
            end

            it "creates a secondary booking option with existing menu" do
              outcome

              created_option = BookingOption.last
              expect(created_option.option_type).to eq("secondary")
              expect(created_option.secondary?).to be true
            end
          end
        end
      end

      context "when adding a new menu" do
        before do
          args[:attrs][:new_menu_name] = "foo"
          args[:attrs][:new_menu_minutes] = 100
          args[:attrs][:new_menu_price] = 100
          args[:attrs][:new_menu_online_state] = true
        end

        it "creates a new booking_page_option, booking_option_menu and menu" do
          expect {
            outcome
          }.to change {
            BookingPageOption.count
          }.and change {
            BookingOptionMenu.count
          }.and change {
            Menu.count
          }.and change {
            BookingOption.count
          }

          new_menu = Menu.last
          expect(BookingOption.last.amount_cents).to eq(100)
          expect(new_menu.name).to eq("foo")
          expect(new_menu.minutes).to eq(100)
          expect(new_menu.online).to eq(true)
        end

        context "with option_type specified" do
          context "when option_type is primary" do
            before do
              args[:attrs][:option_type] = "primary"
            end

            it "creates a primary booking option" do
              outcome

              created_option = BookingOption.last
              expect(created_option.option_type).to eq("primary")
              expect(created_option.primary?).to be true
            end
          end

          context "when option_type is secondary" do
            before do
              args[:attrs][:option_type] = "secondary"
            end

            it "creates a secondary booking option" do
              outcome

              created_option = BookingOption.last
              expect(created_option.option_type).to eq("secondary")
              expect(created_option.secondary?).to be true
            end
          end
        end

        context "without option_type specified" do
          it "defaults to primary" do
            outcome

            created_option = BookingOption.last
            expect(created_option.option_type).to eq("primary")
          end
        end

        context "when booking_page payment_option is online" do
          before do
            booking_page.update(payment_option: "online")
          end

          it "updates online_payment_enabled to true" do
            outcome

            expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(true)
          end
        end

        context "when booking_page payment_option is offline" do
          before do
            booking_page.update(payment_option: "offline")
          end

          it "updates online_payment_enabled to false" do
            outcome

            expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(false)
          end
        end

        context "when booking_page payment_option is custom" do
          before do
            booking_page.update(payment_option: "custom")
            FactoryBot.create(:booking_page_option, booking_page: booking_page, online_payment_enabled: true)
          end

          it "updates online_payment_enabled to true" do
            # When existing online payment option is more than offline payment option
            outcome

            expect(booking_page.booking_page_options.last.online_payment_enabled).to eq(true)
          end
        end
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

        expect(booking_page.start_at).to eq(Time.zone.local(2020, 12, 1, 16, 00))
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

        expect(booking_page.end_at).to eq(Time.zone.local(2020, 12, 1, 16, 00))
      end
    end

    context "update_attribute is special_dates" do
      let(:update_attribute) { "booking_type" }

      before do
        args[:attrs][:special_dates] = [
          {"start_at_date_part"=>"2019-04-22", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-22", "end_at_time_part"=>"12:59"},
          {"start_at_date_part"=>"2019-04-25", "start_at_time_part"=>"01:00", "end_at_date_part"=>"2019-04-25", "end_at_time_part"=>"12:59"}
        ]
      end

      it "updates special_dates" do
        outcome

        expect(booking_page.booking_page_special_dates.pluck(:start_at)).to eq([
          Time.zone.local(2019, 4, 22, 1),
          Time.zone.local(2019, 4, 25, 1),
        ])
        expect(booking_page.booking_page_special_dates.pluck(:end_at)).to eq([
          Time.zone.local(2019, 4, 22, 12, 59),
          Time.zone.local(2019, 4, 25, 12, 59),
        ])
      end
    end
  end
end
