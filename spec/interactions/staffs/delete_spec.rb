require "rails_helper"

RSpec.describe Staffs::Delete do
  let(:staff) { FactoryBot.create(:staff, :with_contact_groups, menus: FactoryBot.create(:menu)) }
  let(:args) do
    {
      staff: staff
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "is disabled" do
      outcome

      expect(staff.deleted_at).to be_present
    end

    it "disables the staff account" do
      outcome

      expect(staff.staff_account).to be_disabled
    end

    it "delete the relationships between staff and shops" do
      expect(staff.shop_staffs).to be_present

      outcome

      expect(staff.shop_staffs).to be_empty
    end

    it "delete the relationships between staff and menus" do
      expect(staff.staff_menus).to be_present

      outcome

      expect(staff.staff_menus).to be_empty
    end

    it "delete the relationships between staff and contact_groups" do
      expect(staff.contact_group_relations).to be_present

      outcome

      expect(staff.contact_group_relations).to be_empty
    end

    it "sends the remind email to notify owner" do
      reservation = FactoryBot.create(:reservation, staff_ids: [staff.id])
    end
  end
end
