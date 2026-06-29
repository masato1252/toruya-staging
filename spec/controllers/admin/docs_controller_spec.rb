# frozen_string_literal: true

require "rails_helper"

RSpec.describe Admin::DocsController, type: :controller do
  let(:admin_user) { FactoryBot.create(:user, skip_default_data: true) }

  before do
    stub_const("User::ADMIN_IDS", [admin_user.id])
    sign_in admin_user
  end

  describe "GET #index" do
    it "returns success" do
      get :index
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST #create" do
    it "creates a doc with auto-generated slug" do
      expect {
        post :create, params: {
          doc: {
            title: "テスト資料",
            document_url: "https://example.com/file.pdf",
            status: "published"
          }
        }
      }.to change(Doc, :count).by(1)

      created = Doc.last
      expect(created.slug).to be_present
      expect(response).to redirect_to(admin_doc_path(created))
    end
  end

  describe "DELETE #destroy" do
    it "soft deletes the doc" do
      doc = FactoryBot.create(:doc)

      delete :destroy, params: { id: doc.id }

      expect(doc.reload.deleted_at).to be_present
      expect(response).to redirect_to(admin_docs_path)
    end
  end
end
