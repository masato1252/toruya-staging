# frozen_string_literal: true

require "rails_helper"

RSpec.describe Lessons::Watch do
  let(:customer) { online_service_customer_relation.customer }
  let(:online_service) { lesson.chapter.online_service }
  let(:lesson) { FactoryBot.create(:lesson) }
  let(:online_service_customer_relation) { FactoryBot.create(:online_service_customer_relation, :paid, online_service: online_service) }
  let(:args) do
    {
      customer: customer,
      lesson: lesson,
      online_service: online_service
    }
  end
  let(:outcome) { described_class.run(args) }

  describe "#execute" do
    it "updates watched_lesson_ids" do
      outcome

      expect(online_service_customer_relation.reload.watched_lesson_ids).to eq([lesson.id.to_s])
    end

    context "when there is custom message for lesson watched" do
      let!(:custom_message) { FactoryBot.create(:custom_message, service: lesson, scenario: CustomMessages::Customers::Template::LESSON_WATCHED) }

      it "sends custom message" do
        expect(Notifiers::Customers::CustomMessages::LessonWatched).to receive(:perform_later).with(
          custom_message: custom_message, receiver: customer
        )

        outcome
      end
    end
  end
end
