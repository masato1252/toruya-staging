# frozen_string_literal: true

require "rails_helper"

RSpec.describe DocDownload, type: :model do
  let(:doc) { FactoryBot.create(:doc) }
  let(:doc_line_user) { FactoryBot.create(:doc_line_user) }

  describe "#record_visit!" do
    it "sets first_visited_at and referrer once" do
      download = FactoryBot.create(:doc_download, doc: doc, doc_line_user: doc_line_user, first_visited_at: nil, referrer: nil)

      download.record_visit!(referrer: "https://google.com")
      download.reload

      expect(download.first_visited_at).to be_present
      expect(download.referrer).to eq("https://google.com")
    end
  end

  describe "#record_download!" do
    it "increments download_count and sets first_downloaded_at" do
      download = doc.doc_downloads.create!(doc_line_user: doc_line_user, referrer: "https://example.com/ref")

      download.record_download!
      download.record_download!

      expect(download.download_count).to eq(2)
      expect(download.first_downloaded_at).to be_present
      expect(download.referrer).to eq("https://example.com/ref")
    end
  end
end
