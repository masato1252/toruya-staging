# frozen_string_literal: true

require "rails_helper"

RSpec.describe Customers::CharFilter do
  let(:user) { staff.user }
  let(:staff) { FactoryBot.create(:staff, :with_contact_groups) }
  let(:readable_contact_group) { staff.readable_contact_groups.first }
  let(:default_customer_options) { { user: user, contact_group: readable_contact_group } }
  let(:args) do
    {
      super_user: user,
      current_user_staff: staff,
      pattern_number: pattern_number
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when matche pattern 3(た ち つ て と タ チ ツ テ ト)" do
      let(:pattern_number) { 3 }
      let!(:matched_customer) { FactoryBot.create(:customer, default_customer_options.merge(phonetic_last_name: "トABC")) }
      let!(:unmatched_customer) { FactoryBot.create(:customer, default_customer_options.merge(phonetic_last_name: "AトBC")) }

      it "returns expected customers" do
        result = outcome.result

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end

      context "there are mulitple customers" do
        let!(:matched_customer2) { FactoryBot.create(:customer, default_customer_options.merge(phonetic_last_name: "たABC")) }

        it "returns expected customers order" do
          result = outcome.result

          expect(result.first).to eq(matched_customer2)
          expect(result.second).to eq(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end
    end
  end
end
