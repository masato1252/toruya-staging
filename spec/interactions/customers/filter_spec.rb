require "rails_helper"

RSpec.describe Customers::Filter do
  let(:user) { FactoryGirl.create(:user) }

  describe "#execute" do
    context "when group_ids option exists" do
      let!(:matched_customer) { FactoryGirl.create(:customer, user: user) }
      let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user) }

      it "returns expected customers" do
        result = Customers::Filter.run!(super_user: user, group_ids: [matched_customer.contact_group_id])

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    context "when region option exists" do
      context "when cities option doesn't exist" do
        let!(:matched_customer) { FactoryGirl.create(:customer, user: user, address: "三重県 亀山市") }
        let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, address: "四重県 桑名市") }

        it "returns expected customers" do
          result = Customers::Filter.run!(super_user: user, region: "三重県")

          expect(result).to include(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end

      context "when cities option exists" do
        let!(:matched_customer) { FactoryGirl.create(:customer, user: user, address: "三重県 亀山市") }
        let!(:matched_customer2) { FactoryGirl.create(:customer, user: user, address: "三重県 亀海市") }
        let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, address: "三重県 桑名市") }

        it "returns expected customers" do
          result = Customers::Filter.run!(super_user: user, region: "三重県", cities: ["亀山市", "亀海市"])

          expect(result).to include(matched_customer)
          expect(result).to include(matched_customer2)
          expect(result).not_to include(unmatched_customer)
        end
      end
    end

    context "when has_email exists" do
      context "When has_email is true" do
        context "when email_types doesn't exists" do
          let!(:matched_customer) { FactoryGirl.create(:customer, user: user, email_types: "mobile") }
          let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user) }

          it "returns expected customers" do
            result = Customers::Filter.run!(super_user: user, has_email: true)

            expect(result).to include(matched_customer)
            expect(result).not_to include(unmatched_customer)
          end
        end

        context "when email_types exists" do
          let!(:matched_customer) { FactoryGirl.create(:customer, user: user, email_types: "mobile,work") }
          let!(:matched_customer2) { FactoryGirl.create(:customer, user: user, email_types: "work") }
          let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, email_types: "home,other") }

          it "returns expected customers" do
            result = Customers::Filter.run!(super_user: user, has_email: true, email_types: ["work", "mobile"])

            expect(result).to include(matched_customer)
            expect(result).to include(matched_customer2)
            expect(result).not_to include(unmatched_customer)
          end
        end
      end

      context "When has_email is false" do
        let!(:matched_customer) { FactoryGirl.create(:customer, user: user) }
        let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, email_types: "mobile") }

        it "returns expected customers" do
          result = Customers::Filter.run!(super_user: user, has_email: false)

          expect(result).to include(matched_customer)
          expect(result).not_to include(unmatched_customer)
        end
      end
    end

    context "when dob_range exists" do
      let!(:matched_customer) { FactoryGirl.create(:customer, user: user, birthday: Date.today) }
      let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, birthday: 2.years.ago) }

      it "returns expected customers" do
        result = Customers::Filter.run!(super_user: user, dob_range: 1.year.ago.beginning_of_day..Date.today.end_of_day)

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end

    context "when custom_id exists" do
      let!(:matched_customer) { FactoryGirl.create(:customer, user: user, custom_id: "fooo") }
      let!(:unmatched_customer) { FactoryGirl.create(:customer, user: user, custom_id: "bar") }

      it "returns expected customers" do
        result = Customers::Filter.run!(super_user: user, custom_id: "Foo")

        expect(result).to include(matched_customer)
        expect(result).not_to include(unmatched_customer)
      end
    end
  end
end
