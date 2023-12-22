# frozen_string_literal: true

require "rails_helper"

RSpec.describe IdentificationCodes::Verify do
  let(:booking_code) { FactoryBot.create(:booking_code) }
  let(:args) do
    {
      uuid: booking_code.uuid,
      code: booking_code.code
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when there is booking_code matched uuid and code" do
      it "returns the matched booking_code" do
        expect(outcome.result).to eq(booking_code)
      end

      context "when booking_code created #{IdentificationCodes::Verify::VALID_TIME_PERIOD} hours before" do
        before do
          Timecop.freeze((IdentificationCodes::Verify::VALID_TIME_PERIOD + 1).hours.ago) do
            booking_code
          end
        end

        it "returns nothing" do
          expect(outcome.result).to be_nil
        end
      end
    end
  end
end
