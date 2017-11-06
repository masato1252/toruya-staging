require "rails_helper"

RSpec.describe Customers::Filter do
  let(:user) { FactoryBot.create(:user) }

  describe "#execute" do
    context "when matche pattern 3(た ち つ て と タ チ ツ テ ト)" do
      let!(:matched_customer) { FactoryBot.create(:customer, user: user, phonetic_last_name: "トABC") }
      let!(:unmatched_customer) { FactoryBot.create(:customer, user: user, phonetic_last_name: "AトBC") }

      it "returns expected customers" do
        result = Customers::Filter.run!(super_user: user, pattern_number: 3)

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end

      context "there are mulitple customers" do
        let!(:matched_customer2) { FactoryBot.create(:customer, user: user, phonetic_last_name: "たABC") }

        it "returns expected customers order" do
          result = Customers::Filter.run!(super_user: user, pattern_number: 3)

          expect(result.first).to eq(matched_customer2)
          expect(result.second).to eq(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end
    end
  end
end
