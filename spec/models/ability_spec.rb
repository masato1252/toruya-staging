require 'rails_helper'

RSpec.describe Ability do
  let(:current_user) { FactoryBot.create(:user) }
  let(:super_user) { current_user }
  let(:ability) { described_class.new(current_user, super_user) }

  RSpec.shared_examples "admin management" do |ability_name, member_level, permission|
    it "#{member_level} member #{permission ? "can" : "cannot" } manage #{ability_name}" do
      allow(super_user).to receive(:member_level).and_return(member_level)

      expect(ability.can?(:manage, ability_name)).to eq(permission)
    end
  end

  describe "can?" do
    context "admin level" do
      {
        "free"    => {
          preset_filter: false,
          saved_filter: false,
        },
        "trial"   => {
          preset_filter: true,
          saved_filter: true,
        },
        "basic"   => {
          preset_filter: true,
          saved_filter: false,
        },
        "premium" => {
          preset_filter: true,
          saved_filter: true,
        },
      }.each do |member_level, permissions|
        permissions.each do |ability_name, permission|
          it_behaves_like "admin management", ability_name, member_level, permission
        end
      end
    end
  end
end
