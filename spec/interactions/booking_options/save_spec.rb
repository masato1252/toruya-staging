# frozen_string_literal: true

require "rails_helper"

RSpec.describe BookingOptions::Save do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_option) { FactoryBot.create(:booking_option, user: user) }
  let(:menu) { FactoryBot.create(:menu, user: user) }
  let(:menu_arguments) do
    { "0" => { "label" => menu.name, "value" => menu.id, "priority" => 0, required_time: menu.minutes } }
  end
  let(:args) do
    {
      booking_option: booking_option,
      attrs: {
        name: "foo",
        display_name: "bar",
        minutes: 60,
        amount_cents: 1000,
        start_at_date_part: DateTime.now.to_fs(:date),
        start_at_time_part: DateTime.now.to_fs(:time),
        menus: menu_arguments
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when booking option is a new record" do
      let(:booking_option) { user.booking_options.new }

      it "creates a booking option" do
        expect {
          outcome
        }.to change {
          user.booking_options.reload.count
        }.by(1)

        expect(user.booking_options.first.menus.first.id).to eq(menu.id)
      end

      context "with option_type specified" do
        it "creates a primary booking option" do
          args[:attrs][:option_type] = "primary"

          expect {
            outcome
          }.to change {
            user.booking_options.reload.count
          }.by(1)

          created_option = user.booking_options.first
          expect(created_option.option_type).to eq("primary")
          expect(created_option.primary?).to be true
        end

        it "creates a secondary booking option" do
          args[:attrs][:option_type] = "secondary"

          expect {
            outcome
          }.to change {
            user.booking_options.reload.count
          }.by(1)

          created_option = user.booking_options.first
          expect(created_option.option_type).to eq("secondary")
          expect(created_option.secondary?).to be true
        end
      end

      context "without option_type specified" do
        it "defaults to primary" do
          expect {
            outcome
          }.to change {
            user.booking_options.reload.count
          }.by(1)

          created_option = user.booking_options.first
          expect(created_option.option_type).to eq("primary")
        end
      end
    end

    it "updates a booking option" do
      expect {
        outcome
      }.to change {
        user.booking_options.first&.menu_ids
      }
    end

    context "updating option_type" do
      it "updates option_type from primary to secondary" do
        booking_option.update!(option_type: "primary")
        args[:attrs][:option_type] = "secondary"

        outcome

        expect(booking_option.reload.option_type).to eq("secondary")
        expect(booking_option.secondary?).to be true
      end

      it "updates option_type from secondary to primary" do
        booking_option.update!(option_type: "secondary")
        args[:attrs][:option_type] = "primary"

        outcome

        expect(booking_option.reload.option_type).to eq("primary")
        expect(booking_option.primary?).to be true
      end
    end

    context "when booking option required_time is less than menu required_time" do
      context "when booking option has only one menu" do
        let(:menu_arguments) do
          {
            "0" => { "label" => menu.name, "value" => menu.id, "priority" => 0, required_time: menu.minutes - 1 },
          }
        end
        let(:booking_option) { user.booking_options.new }

        it "does creates a booking option" do
          expect {
            outcome
          }.to change {
            user.booking_options.reload.count
          }.by(1)

          expect(outcome).to be_valid
        end
      end
    end
  end
end
