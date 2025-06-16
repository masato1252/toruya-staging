require 'rails_helper'

RSpec.describe Surveys::Upsert do
  subject(:interaction) { described_class.run(args) }
  let(:user) { FactoryBot.create(:user) }
  let!(:shop) { FactoryBot.create(:shop, user: user) }
  let(:staff) { FactoryBot.create(:staff) }
  let(:customer) { FactoryBot.create(:customer, user: user) }
  let(:survey) { FactoryBot.create(:survey, user: user, owner: user) }
  let(:question) { FactoryBot.create(:survey_question, survey: survey, question_type: :activity) }
  let(:activity) { FactoryBot.create(:survey_activity, survey_question: question, survey: survey) }
  let!(:slot1) { FactoryBot.create(:survey_activity_slot, survey_activity: activity, start_time: Time.current, end_time: 1.hour.from_now) }
  let!(:slot2) { FactoryBot.create(:survey_activity_slot, survey_activity: activity, start_time: 2.hours.from_now, end_time: 3.hours.from_now) }
  let!(:reservation1) { FactoryBot.create(:reservation, shop: shop, survey_activity: activity, survey_activity_slot: slot1) }
  let!(:reservation2) { FactoryBot.create(:reservation, shop: shop, survey_activity: activity, survey_activity_slot: slot2) }

  before do
    Current.business_owner = user
    allow(user).to receive(:current_staff).and_return(staff)
  end

  let(:args) do
    {
      title: 'Customer Feedback Survey',
      description: 'Please share your thoughts about our service',
      user: user,
      owner: customer,
      questions: [
        {
          description: 'How satisfied were you with our service?',
          question_type: 'text',
          position: 1,
          required: true,
        },
        {
          description: 'How satisfied were you with our service?',
          question_type: 'single_selection',
          position: 2,
          required: true,
          options: [
            {
              content: '1',
              position: 1,
            }
          ]
        },
        {
          description: 'How satisfied were you with our service?',
          question_type: 'multiple_selection',
          position: 3,
          required: true,
          options: [
            {
              content: '1',
              position: 1,
            },
            {
              content: '2',
              position: 2,
            }
          ]
        }
      ]
    }
  end
  let(:outcome) { described_class.run(args) }

  describe '.run' do
    it 'creates a new survey' do
      expect {
        outcome
      }.to change {
        Survey.count
      }.by(1).and change {
        SurveyQuestion.count
      }.by(3).and change {
        SurveyOption.count
      }.by(3)

      survey = outcome.result

      expect(survey.title).to eq(args[:title])
      expect(survey.description).to eq(args[:description])
      expect(survey.user).to eq(args[:user])
      expect(survey.owner).to eq(args[:owner])

      expect(survey.questions.count).to eq(3)
      expect(survey.questions.map(&:options).flatten.count).to eq(3)

      text_question = survey.questions.find_by(question_type: 'text')
      expect(text_question.description).to eq(args[:questions][0][:description])
      expect(text_question.question_type).to eq(args[:questions][0][:question_type])
      expect(text_question.required).to eq(args[:questions][0][:required])
      expect(text_question.position).to eq(args[:questions][0][:position])

      single_selection_question = survey.questions.find_by(question_type: 'single_selection')
      expect(single_selection_question.description).to eq(args[:questions][1][:description])
      expect(single_selection_question.question_type).to eq(args[:questions][1][:question_type])
      expect(single_selection_question.required).to eq(args[:questions][1][:required])
      expect(single_selection_question.position).to eq(args[:questions][1][:position])

      expect(single_selection_question.options.count).to eq(1)
      expect(single_selection_question.options.first.content).to eq(args[:questions][1][:options][0][:content])
      expect(single_selection_question.options.first.position).to eq(args[:questions][1][:options][0][:position])

      multiple_selection_question = survey.questions.find_by(question_type: 'multiple_selection')
      expect(multiple_selection_question.description).to eq(args[:questions][2][:description])
      expect(multiple_selection_question.question_type).to eq(args[:questions][2][:question_type])
      expect(multiple_selection_question.required).to eq(args[:questions][2][:required])
      expect(multiple_selection_question.position).to eq(args[:questions][2][:position])

      expect(multiple_selection_question.options.count).to eq(2)
      expect(multiple_selection_question.options.first.content).to eq(args[:questions][2][:options][0][:content])
      expect(multiple_selection_question.options.first.position).to eq(args[:questions][2][:options][0][:position])
      expect(multiple_selection_question.options.last.content).to eq(args[:questions][2][:options][1][:content])
      expect(multiple_selection_question.options.last.position).to eq(args[:questions][2][:options][1][:position])
    end

    it 'updates an existing survey' do
      existing_survey = outcome.result

      updated_args = args.merge(
        survey: existing_survey,
        title: 'Updated Survey Title',
        questions: [
          {
            id: existing_survey.questions.first.id,
            description: 'Updated question text',
            question_type: 'text',
            position: 1,
            required: false
          }
        ]
      )

      described_class.run(updated_args)

      existing_survey.reload
      expect(existing_survey.title).to eq('Updated Survey Title')
      expect(existing_survey.questions.count).to eq(1)

      survey_question = existing_survey.questions.first
      expect(survey_question.id).to eq(existing_survey.questions.first.id)
      expect(survey_question.options.count).to eq(0)
      expect(survey_question.description).to eq('Updated question text')
      expect(survey_question.required).to be false
    end

    context 'when changing question type' do
      it 'destroys options when question type is changed to text' do
        # First create a survey with a selection question that has options
        survey = described_class.run!(
          user: user,
          owner: customer,
          title: 'Test Survey',
          questions: [
            {
              description: 'Selection Question',
              question_type: 'single_selection',
              position: 1,
              required: true,
              options: [
                { content: 'Option 1', position: 1 },
                { content: 'Option 2', position: 2 }
              ]
            }
          ]
        )

        # Get the question and verify it has options
        question = survey.questions.first
        expect(question.options.count).to eq(2)
        original_option_ids = question.options.pluck(:id)

        # Update the question type to text
        described_class.run!(
          user: user,
          owner: customer,
          survey: survey,
          questions: [
            {
              id: question.id,
              description: 'Now a text question',
              question_type: 'text',
              position: 1,
              required: true
            }
          ]
        )

        # Reload the question and verify options are destroyed
        question.reload
        expect(question.options.count).to eq(0)
        expect(SurveyOption.where(id: original_option_ids)).not_to exist
      end

      it 'destroys options when question type is changed to activity' do
        # First create a survey with a selection question that has options
        survey = described_class.run!(
          user: user,
          owner: customer,
          title: 'Test Survey',
          questions: [
            {
              description: 'Selection Question',
              question_type: 'single_selection',
              position: 1,
              required: true,
              options: [
                { content: 'Option 1', position: 1 },
                { content: 'Option 2', position: 2 }
              ]
            }
          ]
        )

        # Get the question and verify it has options
        question = survey.questions.first
        expect(question.options.count).to eq(2)
        original_option_ids = question.options.pluck(:id)

        # Update the question type to activity
        described_class.run!(
          user: user,
          owner: customer,
          survey: survey,
          questions: [
            {
              id: question.id,
              description: 'Now an activity question',
              question_type: 'activity',
              position: 1,
              required: true,
              activities: [
                {
                  name: 'Test Activity',
                  position: 1,
                  max_participants: 10,
                  price_cents: 2000,
                  currency: 'JPY',
                  datetime_slots: [
                    {
                      start_time: Time.current + 1.day,
                      end_time: Time.current + 1.day + 1.hour,
                      end_date: (Time.current + 1.day + 1.hour).to_date.to_s
                    }
                  ]
                }
              ]
            }
          ]
        )

        # Reload the question and verify options are destroyed
        question.reload
        expect(question.options.count).to eq(0)
        expect(SurveyOption.where(id: original_option_ids)).not_to exist
      end
    end

    it 'does not delete activity if it has responses' do
      # 設置 Current.business_owner 以解決 currency 問題
      Current.business_owner = user
      # 1. 建立一個有 activity 類型問題的 survey
      survey = Surveys::Upsert.run!(
        user: user,
        owner: customer,
        title: 'Test Survey',
        questions: [
          {
            description: 'Activity Question',
            question_type: 'activity',
            position: 1,
            required: true,
            activities: [
              {
                name: 'Yoga Class',
                position: 1,
                max_participants: 10,
                price_cents: 2000,
                currency: 'JPY',
                datetime_slots: [
                  {
                    start_time: Time.current + 1.day,
                    end_time: Time.current + 1.day + 1.hour,
                    end_date: (Time.current + 1.day + 1.hour).to_date.to_s
                  }
                ]
              }
            ]
          }
        ]
      )
      question = survey.questions.first
      activity = question.activities.first

      # 2. 建立 response
      FactoryBot.create(:survey_response, survey: survey, survey_activity: activity, owner: FactoryBot.create(:customer))

      # 3. 嘗試刪除該 activity
      updated_questions = [
        {
          id: question.id,
          description: 'Activity Question',
          question_type: 'activity',
          position: 1,
          required: true,
          activities: [] # 嘗試移除所有 activity
        }
      ]
      Surveys::Upsert.run!(
        user: user,
        owner: customer,
        survey: survey,
        questions: updated_questions
      )

      # 4. 驗證 activity 沒有被刪除
      question.reload
      expect(question.activities.where(id: activity.id)).to exist
    end

    context 'when removing a slot' do
      let(:questions_params) do
        [{
          id: question.id,
          description: question.description,
          question_type: 'activity',
          required: question.required,
          position: question.position,
          activities: [{
            id: activity.id,
            name: activity.name,
            position: activity.position,
            max_participants: activity.max_participants,
            price_cents: activity.price_cents,
            datetime_slots: [{
              id: slot1.id,
              start_time: slot1.start_time,
              end_time: slot1.end_time,
              end_date: slot1.end_time.to_date.to_s
            }]
          }]
        }]
      end

      it 'deletes the reservation for the removed slot' do
        args.merge!(
          survey: survey,
          user: user,
          owner: user,
          questions: questions_params
        )
        expect { described_class.run(args) }.to change(Reservation, :count).by(-1)
          .and change { Reservation.exists?(id: reservation2.id) }.from(true).to(false)
          .and not_change {
            Reservation.exists?(id: reservation1.id)
          }
      end

      it 'deletes the slot' do
        expect {
          described_class.run(
            user: user,
            owner: user,
            survey: survey,
            questions: questions_params
          )
        }.to change(SurveyActivitySlot, :count).by(-1)
          .and change { SurveyActivitySlot.exists?(id: slot2.id) }.from(true).to(false)
          .and not_change { SurveyActivitySlot.exists?(id: slot1.id) }
      end
    end

    describe "when adding a new slot" do
      let(:customer1) { create(:customer, user: user) }
      let(:customer2) { create(:customer, user: user) }
      let!(:reservation1) { FactoryBot.create(:reservation, shop: shop, survey_activity: activity, survey_activity_slot: slot1, customers: [customer1, customer2]) }
      let!(:reservation2) { FactoryBot.create(:reservation, shop: shop, survey_activity: activity, survey_activity_slot: slot2, customers: [customer1, customer2]) }

      context "when activity has both accepted and pending responses" do
        let!(:response1) { create(:survey_response, survey: survey, owner: customer1, survey_activity: activity, state: :accepted) }
        let!(:response2) { create(:survey_response, survey: survey, owner: customer2, survey_activity: activity, state: :pending) }

        let(:questions_params) do
          [{
            id: question.id,
            description: question.description,
            question_type: question.question_type,
            required: question.required,
            position: question.position,
            activities: [{
              id: activity.id,
              name: activity.name,
              position: activity.position,
              max_participants: activity.max_participants,
              price_cents: activity.price_cents,
              datetime_slots: [
                {
                  id: slot1.id,
                  start_time: slot1.start_time,
                  end_time: slot1.end_time,
                  end_date: slot1.end_time.to_date.to_s
                },
                {
                  id: slot2.id,
                  start_time: slot2.start_time,
                  end_time: slot2.end_time,
                  end_date: slot2.end_time.to_date.to_s
                },
                {
                  start_time: Time.current + 2.days,
                  end_time: Time.current + 2.days + 1.hour,
                  end_date: (Time.current + 2.days + 1.hour).to_date.to_s
                }
              ]
            }]
          }]
        end

        it "creates new reservations with correct states" do
          # create a new shop
          args.merge!(
            survey: survey,
            user: user,
            owner: customer,
            questions: questions_params
          )

          expect {
            outcome
          }.to change(Reservation, :count).by(1)
            .and change(ReservationStaff, :count).by(1)
            .and change(ReservationCustomer, :count).by(2)

          # Check new slot was created
          new_slot = SurveyActivitySlot.last
          expect(new_slot).not_to eq(slot1)
          expect(new_slot).not_to eq(slot2)

          # Check reservations for new slot
          new_reservations = Reservation.where(survey_activity_slot: new_slot)
          expect(new_reservations.count).to eq(1)

          # Check reservation staff states (should all be accepted because there's at least one accepted response)
          new_reservations.each do |reservation|
            expect(reservation.reservation_staffs.first.state).to eq(ReservationStaff::ACCEPTED_STATE)
          end

          # Check reservation customer states (should match their survey response states)
          customer1_reservation = ReservationCustomer.find_by(reservation: new_reservations.first, customer: customer1)
          customer2_reservation = ReservationCustomer.find_by(reservation: new_reservations.first, customer: customer2)

          expect(customer1_reservation.state).to eq("accepted")
          expect(customer2_reservation.state).to eq("pending")
        end
      end
    end
  end
end
