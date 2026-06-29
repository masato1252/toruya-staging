# frozen_string_literal: true

require "rails_helper"

RSpec.describe ControllerHelpers, type: :controller do
  controller(ActionController::Base) do
    include ControllerHelpers

    def index
      capture_doc_landing_referrer(params[:slug])
      render plain: session[doc_referrer_session_key_for(params[:slug])] || ""
    end
  end

  before do
    routes.draw { get "index" => "anonymous#index" }
  end

  describe "#meaningful_doc_referrer" do
    it "returns external referrers" do
      expect(controller.send(:meaningful_doc_referrer, "https://google.com/search")).to eq("https://google.com/search")
    end

    it "returns nil for LINE OAuth hosts" do
      expect(controller.send(:meaningful_doc_referrer, "https://access.line.me/oauth2/v2.1/authorize")).to be_nil
    end
  end

  describe "#capture_doc_landing_referrer" do
    it "stores first-touch external referer in session" do
      request.env["HTTP_REFERER"] = "https://partner.example/article"
      get :index, params: { slug: "abc123" }

      expect(session["doc_ref_abc123"]).to eq("https://partner.example/article")
    end

    it "does not store LINE OAuth referer" do
      request.env["HTTP_REFERER"] = "https://access.line.me/"
      get :index, params: { slug: "abc123" }

      expect(session["doc_ref_abc123"]).to be_nil
    end
  end
end
