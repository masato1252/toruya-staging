require "rails_helper"

RSpec.describe StaffContactGroupRelations::Create do
  let(:staff) { FactoryBot.create(:staff) }
  let(:contact_group) { FactoryBot.create(:contact_group, user: staff.user) }
  let(:args) do
    {
      staff: staff,
      contact_group: contact_group,
      contact_group_read_permission: "details_readable"
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "creates a staff_contact_group_relation" do
      expect {
        outcome
      }.to change {
        staff.contact_group_relations.count
      }.from(0).to(1)

      expect(staff.contact_group_relations.first).to be_details_readable
    end
  end
end
