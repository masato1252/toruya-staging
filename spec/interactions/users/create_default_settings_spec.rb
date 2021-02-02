# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::CreateDefaultSettings do
  let(:profile) { FactoryBot.create(:profile) }
  let(:user) { profile.user }
  let(:args) do
    {
      user: user
    }
  end
  let(:outcome) { described_class.run!(args) }

  describe "#execute" do
    it "creates expected records" do
      expect {
        outcome
      }.to change {
        user.shops.count
      }.by(1).and change {
        BusinessSchedule.where(shop: user.shops.first, business_state: "opened").count
      }.by(5).and change {
        BusinessSchedule.where(shop: user.shops.first, business_state: "closed").count
      }.by(2).and change {
        user.reservation_settings.count
      }.by(1).and change {
        user.menus.count
      }.by(1).and change {
        user.contact_groups.count
      }.by(1).and change {
        BusinessSchedule.where(shop: user.shops.first, staff: user.current_staff(user)).count
      }.by(1)
    end
  end
end
