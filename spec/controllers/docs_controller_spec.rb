# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocsController, type: :controller do
  render_views false

  let(:doc) { FactoryBot.create(:doc) }
  let(:doc_line_user) { FactoryBot.create(:doc_line_user) }

  describe "GET #show" do
    it "returns success for published doc" do
      get :show, params: { slug: doc.slug }
      expect(response).to have_http_status(:ok)
    end

    it "returns not found for unpublished doc" do
      doc.update!(status: :unpublished)

      get :show, params: { slug: doc.slug }
      expect(response).to have_http_status(:not_found)
    end

    it "records visit for logged-in doc line user" do
      session[:doc_line_user_id] = doc_line_user.id
      request.env["HTTP_REFERER"] = "https://referrer.example/page"

      expect {
        get :show, params: { slug: doc.slug }
      }.to change { doc.doc_downloads.count }.by(1)

      download = doc.doc_downloads.last
      expect(download.doc_line_user).to eq(doc_line_user)
      expect(download.first_visited_at).to be_present
      expect(download.referrer).to eq("https://referrer.example/page")
    end

    it "does not overwrite landing referrer with LINE OAuth referer after login" do
      session[:doc_line_user_id] = doc_line_user.id
      session["doc_ref_#{doc.slug}"] = "https://campaign.example/landing"

      request.env["HTTP_REFERER"] = "https://access.line.me/oauth2/v2.1/authorize"
      get :show, params: { slug: doc.slug }

      download = doc.doc_downloads.find_by!(doc_line_user: doc_line_user)
      expect(download.referrer).to eq("https://campaign.example/landing")
      expect(session["doc_ref_#{doc.slug}"]).to eq("https://campaign.example/landing")
    end

    it "ignores LINE OAuth referer when no prior landing referrer was captured" do
      session[:doc_line_user_id] = doc_line_user.id
      request.env["HTTP_REFERER"] = "https://access.line.me/oauth2/v2.1/authorize"

      get :show, params: { slug: doc.slug }

      download = doc.doc_downloads.find_by!(doc_line_user: doc_line_user)
      expect(download.referrer).to be_nil
      expect(session["doc_ref_#{doc.slug}"]).to be_nil
    end
  end

  describe "POST #download" do
    it "redirects to login flow when not logged in" do
      post :download, params: { slug: doc.slug }
      expect(response).to redirect_to(doc_path(slug: doc.slug))
    end

    it "redirects to document url and increments download count" do
      session[:doc_line_user_id] = doc_line_user.id
      session["doc_ref_#{doc.slug}"] = "https://campaign.example"

      post :download, params: { slug: doc.slug }

      expect(response).to redirect_to(doc.document_url)
      download = doc.doc_downloads.find_by!(doc_line_user: doc_line_user)
      expect(download.download_count).to eq(1)
      expect(download.first_downloaded_at).to be_present
      expect(download.referrer).to eq("https://campaign.example")
    end
  end
end
