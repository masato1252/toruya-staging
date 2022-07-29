# frozen_string_literal: true

require "rails_helper"

RSpec.describe Templates::ReservationVariables do
  let(:receiver) { FactoryBot.create(:customer) }
  let(:shop) { FactoryBot.create(:shop, user: receiver.user) }
  let(:meeting_url) { nil }
  let(:args) do
    {
      receiver: receiver,
      shop: shop,
      start_time: Time.current,
      end_time: Time.current.tomorrow,
      meeting_url: meeting_url
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    context "when meeting_url could not parsed" do
      let(:meeting_url) { nil }

      it 'returns original meeting_url' do
        expect(outcome.result[:meeting_url]).to eq('')
      end
    end

    context "when meeting_url was able to parse" do
      let(:meeting_url) { 'https://toruya.com' }

      it 'append openExternalBrowser=1 as parameter' do
        expect(outcome.result[:meeting_url]).to eq("#{meeting_url}?openExternalBrowser=1")
      end

      context "when meeting_url already had openExternalBrowser=1" do
        let(:meeting_url) { 'https://toruya.com?abc=def&openExternalBrowser=1' }

        it 'returns original meeting_url' do
          expect(outcome.result[:meeting_url]).to eq("https://toruya.com?abc=def&openExternalBrowser=1")
        end
      end
    end
  end
end
