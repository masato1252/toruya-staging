require "rails_helper"

RSpec.describe Notifiers::Customers::Surveys::ActivityPendingResponse, type: :interaction do
  let(:user) { create(:profile).user }
  let(:customer) { create(:customer, user: user) }
  let(:survey) { create(:survey, user: user) }
  let(:survey_activity) { create(:survey_activity, survey: survey) }
  let(:survey_response) { create(:survey_response, survey: survey, owner: customer, survey_activity: survey_activity) }

  subject { described_class.new(survey_response: survey_response, receiver: customer) }

  describe "#message" do
    it "returns the translated message with variables replaced" do
      # The template for ACTIVITY_PENDING_RESPONSE is defined in I18n as 'notifier.survey.reply.activity_pending_message'
      # and the variable is %{reply_survey_url}. We'll set up the translation and check the output.
      I18n.backend.store_translations(:ja, {
        notifier: {
          survey: {
            reply: {
              activity_pending_message: "Please reply here: %{reply_survey_url}"
            }
          }
        }
      })

      expected_url = Rails.application.routes.url_helpers.reply_survey_url(survey.slug, survey_response.uuid)
      expect(subject.send(:message)).to eq("Please reply here: #{expected_url}")
    end
  end

  describe "#execute" do
    it "sets the locale to the customer's locale and calls super" do
      expect(I18n).to receive(:with_locale).with(customer.locale).and_call_original
      expect { subject.execute }.not_to raise_error
    end
  end
end
