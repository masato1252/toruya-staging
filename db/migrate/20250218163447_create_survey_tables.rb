class CreateSurveyTables < ActiveRecord::Migration[6.1]
  def change
    create_table :surveys do |t|
      t.string :title
      t.text :description
      t.boolean :active, default: true
      t.references :user, null: false
      t.references :owner, polymorphic: true # booking page
      t.string :scenario
      t.timestamps
    end

    create_table :survey_questions do |t|
      t.references :survey, null: false
      t.text :description, null: false
      t.string :question_type, null: false # text, single_selection, multiple_selection
      t.boolean :required, default: false
      t.integer :position
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :survey_options do |t|
      t.references :survey_question, null: false
      t.string :content, null: false
      t.integer :position
      t.datetime :deleted_at
      t.timestamps
    end

    create_table :survey_responses do |t|
      t.references :survey, null: false
      t.references :owner, polymorphic: true # who filled the survey
      t.timestamps
    end

    # create a snapshot of the survey questions and options
    create_table :question_answers do |t|
      t.references :survey_response, null: false
      t.references :survey_question, null: false
      t.references :survey_option # for single/multiple selection
      t.text :survey_question_snapshot, null: false
      t.text :survey_option_snapshot # for single/multiple selection
      t.text :text_answer # for text questions
      t.timestamps
    end
  end
end