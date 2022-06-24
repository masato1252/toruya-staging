
# frozen_string_literal: true

require "rails_helper"

RSpec.describe Sales::OnlineServices::Create do
  before { StripeMock.start }
  after { StripeMock.stop }
  let(:user) { FactoryBot.create(:access_provider, :stripe).user }
  let(:online_service) { FactoryBot.create(:online_service, user: user) }
  let(:sale_template) { FactoryBot.create(:sale_template) }
  let(:staff) { FactoryBot.create(:staff, user: user) }
  let(:monthly_price) { nil }

  let(:args) do
    {
      user: user,
      selected_online_service_id: online_service.id,
      selected_template_id: sale_template.id,
      template_variables: {},
      introduction_video_url: "url",
      monthly_price: monthly_price,
      content: {
        picture: Tempfile.new,
        desc1: "desc1",
        desc2: "desc2"
      },
      staff: {
        id: staff.id,
        introduction: "introduction"
      }
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it 'creates a sale page' do
      # I suck, I could not test upload file successfully
      expect(user.sale_pages).to receive(:create).and_return(FactoryBot.create(:sale_page, :online_service))

      outcome
    end

    context "when service is recurring charged (with monthly_price or yearly_price)" do
      let(:monthly_price) { 1_000 }

      it "creates a stripe product" do
        expect(user.sale_pages).to receive(:create).and_return(FactoryBot.create(:sale_page, :online_service))

        outcome

        online_service.reload
        expect(
          Stripe::Product.retrieve(
            online_service.stripe_product_id,
            {
              stripe_account: online_service.user.stripe_provider.uid
            }
          )
        ).to be_present
      end
    end
  end
end
