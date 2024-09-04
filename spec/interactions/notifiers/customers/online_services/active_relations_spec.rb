# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notifiers::Customers::OnlineServices::ActiveRelations, :with_line do
  let!(:receiver) { FactoryBot.create(:social_customer, customer: relation.customer).customer }
  let(:relation) { FactoryBot.create(:online_service_customer_relation, :free) }

  let(:args) do
    {
      receiver: receiver
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "sends line" do
      expect(LineClient).to receive(:flex)
      expect {
        outcome
      }.to change {
        SocialMessage.where(
          social_customer: receiver.social_customer
        ).count
      }.by(1)
    end

    context "when customer got more than COLUMNS_NUMBER_LIMIT services" do
      let!(:second_relation) { FactoryBot.create(:online_service_customer_relation, :free, customer: receiver) }
      let!(:third_relation) { FactoryBot.create(:online_service_customer_relation, :free, customer: receiver) }

      it "adds next card" do
        stub_const("LineClient::COLUMNS_NUMBER_LIMIT", 2)
        expect(LineMessages::FlexTemplateContent).to receive(:next_card).with(
          action_template: LineActions::Message.template(
            text: "#{I18n.t("common.more")} - #{I18n.t("line.bot.keywords.services")} #{third_relation.id}",
            label: "More"
          )
        ).once.and_call_original

        outcome
      end
    end
  end
end
