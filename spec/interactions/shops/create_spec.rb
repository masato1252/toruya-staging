require "rails_helper"

RSpec.describe Shops::Create do
  let(:profile) { FactoryBot.create(:profile) }
  let(:user) { profile.user }
  let(:params) do
    {
      name: "czsdadqweqw",
      short_name: "adqweqweqweqweq",
      zip_code: "71081",
      address: "4F.-3 , No.125, Sinsing St",
      phone_number: "qweqwe",
      email: "dada",
      website: ""
    }.with_indifferent_access
  end
  let(:args) do
    {
      user: user,
      params: params,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when a new shop be created" do
      it "assigns the new shop to user's mapping staff" do
        outcome

        expect(user.current_staff(user).shop_ids).to eq(user.shop_ids)
      end
    end
  end
end
