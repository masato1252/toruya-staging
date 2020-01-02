require "rails_helper"

RSpec.describe Users::BuildDefaultData do
  let(:args) do
    {
      user: user,
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when user is a new user" do
      let(:user) { FactoryBot.build(:user) }

      it "had ranks and subscription" do
        outcome

        expect(user.ranks).to be_present
        expect(user.subscription).to be_present
      end
    end

    context "when user is a existing user" do
      let(:user) { FactoryBot.create(:user) }

      it "had ranks and subscription" do
        outcome

        expect(user.ranks).to be_present
        expect(user.subscription).to be_present
      end
    end
  end
end
