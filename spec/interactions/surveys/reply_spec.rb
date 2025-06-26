require 'rails_helper'

RSpec.describe Surveys::Reply do
  before do
    allow(user).to receive(:current_staff).and_return(FactoryBot.create(:staff, user: user))
  end

  let(:user) { FactoryBot.create(:user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:customer) { FactoryBot.create(:customer) }
  let(:another_customer) { FactoryBot.create(:customer) }

  let(:survey) do
    Surveys::Upsert.run!(
      title: 'Customer Feedback Survey',
      description: 'Please share your thoughts about our service',
      user: user,
      owner: booking_page,
      currency: 'JPY',
      questions: [
        {
          description: 'How satisfied were you with our service?',
          question_type: 'text',
          position: 1,
          required: true,
        },
        {
          description: 'Would you recommend us?',
          question_type: 'single_selection',
          position: 2,
          required: true,
          options: [
            {
              content: 'Yes',
              position: 1,
            },
            {
              content: 'No',
              position: 2,
            }
          ]
        },
        {
          description: '<p>This is a <strong>formatted</strong> question with <em>HTML</em> that should be truncated at 100 characters</p>',
          question_type: 'text',
          position: 3,
          required: false,
        },
        {
          description: 'Select an activity',
          question_type: 'activity',
          position: 4,
          required: true,
          activities: [
            {
              name: 'Yoga Class',
              position: 1,
              max_participants: 2,
              price_cents: 2000,
              currency: 'JPY',
              datetime_slots: [
                {
                  start_time: 1.day.from_now,
                  end_time: 1.day.from_now + 1.hour,
                  end_date: (1.day.from_now + 1.hour).to_date.to_s
                }
              ]
            }
          ]
        }
      ]
    )
  end

  let(:text_question) { survey.questions.find_by(question_type: 'text', position: 1) }
  let(:single_selection_question) { survey.questions.find_by(question_type: 'single_selection') }
  let(:html_question) { survey.questions.find_by(position: 3) }
  let(:activity_question) { survey.questions.find_by(question_type: 'activity') }
  let(:activity) { activity_question.activities.first }
  let(:yes_option) { single_selection_question.options.find_by(content: 'Yes') }

  subject(:interaction) { described_class.run(args) }

  let(:args) do
    {
      survey: survey,
      owner: customer,
      answers: [
        {
          survey_question_id: text_question.id,
          text_answer: 'Very satisfied with the service'
        },
        {
          survey_question_id: single_selection_question.id,
          survey_option_ids: [yes_option.id]
        },
        {
          survey_question_id: html_question.id,
          text_answer: 'Answer to HTML question'
        },
        {
          survey_question_id: activity_question.id,
          survey_activity_id: activity.id
        }
      ]
    }
  end

  let(:required_answers) do
    [
      {
        survey_question_id: text_question.id,
        text_answer: 'Very satisfied with the service'
      },
      {
        survey_question_id: single_selection_question.id,
        survey_option_ids: [yes_option.id]
      }
    ]
  end

  describe '.run' do
    it 'creates a new survey response with answers' do
      expect {
        interaction
      }.to change {
        SurveyResponse.count
      }.by(1).and change {
        QuestionAnswer.count
      }.by(4)

      expect(interaction).to be_valid
      response = interaction.result

      expect(response.owner).to eq(customer)
      expect(response.survey).to eq(survey)
      expect(response.survey_activity).to eq(activity)

      text_answer = response.question_answers.find_by(survey_question: text_question)
      expect(text_answer.text_answer).to eq('Very satisfied with the service')
      expect(text_answer.survey_option_id).to be_nil

      selection_answer = response.question_answers.find_by(survey_question: single_selection_question)
      expect(selection_answer.survey_option_id).to eq(yes_option.id)
      expect(selection_answer.text_answer).to be_nil

      html_answer = response.question_answers.find_by(survey_question: html_question)
      expect(html_answer.text_answer).to eq('Answer to HTML question')
      expect(html_question.description).to include('<strong>formatted</strong>')

      activity_answer = response.question_answers.find_by(survey_question: activity_question)
      expect(activity_answer.survey_activity_id).to eq(activity.id)
      expect(activity_answer.survey_activity_snapshot).to eq('Yoga Class')
    end

    context 'with missing required questions' do
      let(:args) do
        {
          survey: survey,
          owner: customer,
          answers: [] # No answers provided
        }
      end

      it 'adds :missing_required error when required questions are not answered' do
        expect(interaction).not_to be_valid
        expect(interaction.errors.details[:survey]).to include(error: :missing_required)
      end

      it 'adds :missing_required error when some required questions are missing' do
        # Only answer the text question
        args[:answers] = [
          {
            survey_question_id: text_question.id,
            text_answer: 'Some answer'
          }
        ]

        expect(interaction).not_to be_valid
        expect(interaction.errors.details[:survey]).to include(error: :missing_required)
      end

      it 'is valid when all required questions are answered' do
        # Answer all required questions but skip the optional one (html_question)
        args[:answers] = [
          {
            survey_question_id: text_question.id,
            text_answer: 'Very satisfied with the service'
          },
          {
            survey_question_id: single_selection_question.id,
            survey_option_ids: [yes_option.id]
          },
          {
            survey_question_id: activity_question.id,
            survey_activity_id: activity.id
          }
        ]

        expect(interaction).to be_valid
        expect(interaction.errors[:survey]).to be_empty
      end
    end

    context 'with invalid answer format' do
      let(:args) do
        {
          survey: survey,
          owner: customer,
          answers: [
            {
              survey_question_id: text_question.id,
              survey_option_ids: [yes_option.id] # invalid for text question
            },
            {
              survey_question_id: single_selection_question.id,
              text_answer: 'Yes' # invalid for single selection question
            }
          ]
        }
      end

      it 'is invalid' do
        expect(interaction).not_to be_valid
        expect(interaction.errors.details[:survey]).to include(error: :options_not_allowed)
        expect(interaction.errors.details[:survey]).to include(error: :text_answer_not_allowed)
      end
    end

    context 'with HTML content in question description' do
      it 'handles HTML content in question description' do
        expect(interaction).to be_valid
        response = interaction.result
        html_answer = response.question_answers.find_by(survey_question: html_question)
        expect(html_answer.text_answer).to eq('Answer to HTML question')
        expect(html_question.description).to include('<strong>formatted</strong>')
      end
    end

    context 'when submitting duplicate activity response' do
      before do
        # Create a previous response for the same activity
        described_class.run!(
          survey: survey,
          owner: customer,
          answers: required_answers + [
            {
              survey_question_id: activity_question.id,
              survey_activity_id: activity.id
            }
          ]
        )
      end

      it 'is invalid' do
        expect(interaction).not_to be_valid
        expect(interaction.errors.details[:survey].first[:error]).to eq(:duplicate_activity)
      end

      it 'does not create a new response' do
        expect {
          interaction
        }.not_to change(SurveyResponse, :count)
      end
    end

    context 'when submitting response for a different activity' do
      let(:new_activity) do
        activity = activity_question.activities.create!(
          survey: survey,
          name: 'Meditation Class',
          position: 2,
          max_participants: 15,
          price_cents: 1500,
          currency: 'JPY'
        )

        activity.activity_slots.create!(
          start_time: Time.current + 2.days,
          end_time: Time.current + 2.days + 1.hour
        )

        activity
      end

      before do
        # Create a previous response for a different activity
        described_class.run!(
          survey: survey,
          owner: customer,
          answers: required_answers + [
            {
              survey_question_id: activity_question.id,
              survey_activity_id: activity.id
            }
          ]
        )
      end

      let(:args) do
        {
          survey: survey,
          owner: customer,
          answers: required_answers + [
            {
              survey_question_id: activity_question.id,
              survey_activity_id: new_activity.id
            }
          ]
        }
      end

      it 'is valid' do
        expect(interaction).to be_valid
      end

      it 'creates a new response' do
        expect {
          interaction
        }.to change(SurveyResponse, :count).by(1)
      end
    end
  end

  describe '#execute' do
    context 'when answering an activity question' do
      let(:answers) do
        required_answers + [
          {
            survey_question_id: activity_question.id,
            survey_activity_id: activity.id
          }
        ]
      end

      it 'creates a survey response with activity answer' do
        outcome = described_class.run(survey: survey, owner: customer, answers: answers)
        expect(outcome).to be_valid
        expect(outcome.result).to be_a(SurveyResponse)
        expect(outcome.result.survey_activity).to eq(activity)
      end

      context 'when no existing reservation exists' do
        it 'creates a new reservation for the activity slot' do
          expect {
            described_class.run(survey: survey, owner: customer, answers: answers)
          }.to change(Reservation, :count).by(1)

          reservation = Reservation.last
          expect(reservation.start_time).to eq(activity.activity_slots.first.start_time)
          expect(reservation.end_time).to eq(activity.activity_slots.first.end_time)
          expect(reservation.shop).to eq(user.shop)
          expect(reservation.count_of_customers).to eq(1)
          expect(reservation.survey_activity).to eq(activity)
        end
      end

      context 'when an existing reservation exists' do
        let!(:existing_reservation) do
          Reservation.find_by(survey_activity: activity, survey_activity_slot: activity.activity_slots.first)
        end

        before do
          ReservationCustomer.create!(
            reservation: existing_reservation,
            customer: another_customer,
            state: :pending,
            survey_activity_id: activity.id,
            slug: SecureRandom.alphanumeric(10)
          )
        end

        it 'reuses the existing reservation' do
          expect {
            described_class.run(survey: survey, owner: customer, answers: answers)
          }.not_to change(Reservation, :count)

          existing_reservation.reload
          expect(existing_reservation.count_of_customers).to eq(2)
        end

        it 'creates a new reservation customer record' do
          expect {
            described_class.run(survey: survey, owner: customer, answers: answers)
          }.to change(ReservationCustomer, :count).by(1)

          reservation_customer = ReservationCustomer.last
          expect(reservation_customer.customer).to eq(customer)
          expect(reservation_customer.state).to eq('pending')
          expect(reservation_customer.survey_activity_id).to eq(activity.id)
          expect(reservation_customer.reservation).to eq(existing_reservation)
        end
      end

      context 'when activity is at max participants' do
        before do
          2.times do
            FactoryBot.create(:survey_response, survey: survey, survey_activity: activity)
          end
        end

        it 'fails validation' do
          outcome = described_class.run(survey: survey, owner: customer, answers: answers)
          expect(outcome).not_to be_valid
          expect(outcome.errors.details[:survey]).to include(error: :activity_full)
        end
      end

      context 'when customer has already responded to the activity' do
        before do
          previous_response = create(:survey_response, survey: survey, survey_activity: activity, owner: customer)
          create(:question_answer,
            survey_response: previous_response,
            survey_question: activity_question,
            survey_activity: activity
          )
        end

        it 'fails validation' do
          outcome = described_class.run(survey: survey, owner: customer, answers: answers)
          expect(outcome).not_to be_valid
          expect(outcome.errors.details[:survey].first[:error]).to eq(:duplicate_activity)
        end
      end
    end
  end
end
