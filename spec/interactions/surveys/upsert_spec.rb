require 'rails_helper'

RSpec.describe Surveys::Upsert do
  subject(:interaction) { described_class.run(args) }
  let(:user) { FactoryBot.create(:user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }

  let(:args) do
    {
      title: 'Customer Feedback Survey',
      description: 'Please share your thoughts about our service',
      user: user,
      owner: booking_page,
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

    it 'soft deletes options when question type is changed to text' do
      # First create a survey with a selection question that has options
      survey = described_class.run!(
        user: user,
        owner: booking_page,
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
        owner: booking_page,
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

      # Reload the question and verify options are soft deleted
      question.reload
      expect(question.options.count).to eq(0)
      expect(question.options.unscoped.where(id: original_option_ids).where.not(deleted_at: nil).count).to eq(2)
    end
  end
end
