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

  RSpec.shared_examples "updates normal attribute" do |attribute, value|
    let(:update_attribute) { attribute }
    before { args[:attrs][attribute] = value }

    it "updates #{attribute} to #{value}" do
      outcome

      expect(booking_page.public_send(attribute)).to eq(value)
    end
  end

  describe "#execute" do
    context "update_attribute is name" do
      it_behaves_like "updates normal attribute", "name", "foo"
    end

    context "update_attribute is title" do
      it_behaves_like "updates normal attribute", "title", "foo"
    end

    context "update_attribute is draft" do
      it_behaves_like "updates normal attribute", "draft", true
      it_behaves_like "updates normal attribute", "draft", false
    end

    context "update_attribute is line_sharing" do
      it_behaves_like "updates normal attribute", "line_sharing", true
      it_behaves_like "updates normal attribute", "line_sharing", false
    end

    context "update_attribute is shop_id" do
      it_behaves_like "updates normal attribute", "shop_id", 1
    end

    context "update_attribute is booking_limit_day" do
      it_behaves_like "updates normal attribute", "booking_limit_day", 3
    end

    context "update_attribute is greeting" do
      it_behaves_like "updates normal attribute", "greeting", "foo"
    end

    context "update_attribute is note" do
      it_behaves_like "updates normal attribute", "note", "foo"
    end

    context "update_attribute is interval" do
      it_behaves_like "updates normal attribute", "interval", 60
    end

    context "update_attribute is overbooking_restriction" do
      it_behaves_like "updates normal attribute", "overbooking_restriction", true
      it_behaves_like "updates normal attribute", "overbooking_restriction", false
    end

    context "update_attribute is new_option" do
      let(:update_attribute) { "new_option" }
      let(:new_booking_option) { FactoryBot.create(:booking_option, user: user) }
      before do
        args[:attrs][:new_option] = new_booking_option.id
      end

      it "creates a new booking_page_option" do
        outcome

        last_booking_option = booking_page.booking_page_options.last

        expect(last_booking_option.booking_option_id).to eq(new_booking_option.id)
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
      let(:update_attribute) { "special_dates" }

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
