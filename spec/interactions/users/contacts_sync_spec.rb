require "rails_helper"

RSpec.describe Users::ContactsSync do
  let(:user) { FactoryBot.create(:user) }
  let(:args) do
    {
      user: user
    }
  end
  let(:outcome) { described_class.run!(args) }
  let(:contact_group) { FactoryBot.create(:contact_group, user: user) }

  before do
    contact_group
  end

  describe "#execute" do
    context "when user doesn't access Toruya today" do
      it "updates the contacts_sync_at" do
        expect {
          outcome
        }.to change {
          user.contacts_sync_at
        }
      end

      it "imports user all connected groups" do
        expect(CustomersImporterJob).to receive(:perform_later).with(contact_group, false).once

        outcome
      end
    end

    context "when user already accessed today" do
      it "won't change contacts_sync_at" do
        outcome

        expect {
          outcome
        }.not_to change {
          user.contacts_sync_at
        }
      end
    end
  end
end
