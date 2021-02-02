# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ContactGroup, type: :model do
  describe "#validates" do
    context "when user already owns a bind_all contact_group" do
      let(:contact_group) { FactoryBot.create(:contact_group, :bind_all) }

      context "when user create another bind_all contact_group" do
        it "is invalid" do
          expect(FactoryBot.build(:contact_group, :bind_all, user: contact_group.user)).to be_invalid
        end
      end

      context "when user create a normal contact_group" do
        it "is valid" do
          expect(FactoryBot.create(:contact_group, user: contact_group.user)).to be_valid
        end

        context "when user force to change a normal contact_group to bind_all" do
          it "" do
            group = FactoryBot.create(:contact_group, user: contact_group.user)

            expect {
              group.update_columns(bind_all: true)
            }.to raise_error(ActiveRecord::RecordNotUnique)
          end
        end
      end
    end
  end
end
