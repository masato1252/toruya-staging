require 'rails_helper'

RSpec.describe Surveys::Reply do
  let(:user) { FactoryBot.create(:user) }
  let(:booking_page) { FactoryBot.create(:booking_page, user: user) }
  let(:customer) { FactoryBot.create(:customer) }

  let(:survey) do
    Surveys::Upsert.run!(
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
        }
      ]
    )
  end

  let(:text_question) { survey.questions.find_by(question_type: 'text', position: 1) }
  let(:single_selection_question) { survey.questions.find_by(question_type: 'single_selection') }
  let(:html_question) { survey.questions.find_by(position: 3) }
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
        }
      ]
    }
  end

  describe '.run' do
    it 'creates a new survey response with answers' do
      expect {
        interaction
      }.to change {
        SurveyResponse.count
      }.by(1).and change {
        QuestionAnswer.count
      }.by(3)

      expect(interaction).to be_valid
      response = interaction.result

      expect(response.owner).to eq(customer)
      expect(response.survey).to eq(survey)

      text_answer = response.question_answers.find_by(survey_question: text_question)
      expect(text_answer.text_answer).to eq('Very satisfied with the service')
      expect(text_answer.survey_option_id).to be_nil

      selection_answer = response.question_answers.find_by(survey_question: single_selection_question)
      expect(selection_answer.survey_option_id).to eq(yes_option.id)
      expect(selection_answer.text_answer).to be_nil

      html_answer = response.question_answers.find_by(survey_question: html_question)
      expect(html_answer.text_answer).to eq('Answer to HTML question')
      expect(html_question.description).to include('<strong>formatted</strong>')
    end

    context 'with missing required question' do
      let(:args) do
        {
          survey: survey,
          owner: customer,
          answers: [
            {
              survey_question_id: text_question.id,
              text_answer: 'Very satisfied with the service'
            }
          ]
        }
      end

      it 'is invalid' do
        expect(interaction).not_to be_valid
        expect(interaction.errors[:answers]).to include(/Missing answers for required questions/)
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
        expect(interaction.errors[:answers]).to include(/Survey options should not be present for text question/)
        expect(interaction.errors[:answers]).to include(/Text answer should not be present for single selection question/)
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
  end
end