# frozen_string_literal: true

require "rails_helper"

RSpec.describe Doc, type: :model do
  describe "slug assignment" do
    it "assigns a unique 12-character alphanumeric slug on create" do
      doc = FactoryBot.create(:doc)

      expect(doc.slug).to match(/\A[a-zA-Z0-9]{12}\z/)
    end
  end

  describe "scopes" do
    it "excludes soft-deleted records from active scope" do
      active = FactoryBot.create(:doc)
      deleted = FactoryBot.create(:doc)
      deleted.soft_delete!

      expect(Doc.active).to contain_exactly(active)
    end
  end
end
