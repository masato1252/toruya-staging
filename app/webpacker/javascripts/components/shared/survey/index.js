import React, { useState } from 'react'
import TextareaAutosize from 'react-autosize-textarea';
import { Editor } from 'react-draft-wysiwyg';
import { EditorState, ContentState, convertToRaw } from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';

const QUESTION_TYPES = {
  text: 'Text',
  single_selection: 'Single Selection',
  multiple_selection: 'Multiple Selection',
  dropdown: 'Dropdown'
}

const SurveyBuilder = ({ onSubmit, initialData = {}, skip_header = false }) => {
  const [title, setTitle] = useState(initialData?.title || '')
  const [description, setDescription] = useState(initialData?.description || '')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [editorStates, setEditorStates] = useState(() => {
    const initialQuestions = initialData?.questions || [{
      id: null,
      description: '',
      question_type: 'text',
      required: false,
      position: 0,
      options: [],
    }]

    return initialQuestions.map(question => {
      if (!question.description) {
        return EditorState.createEmpty();
      }
      const contentState = ContentState.createFromBlockArray(
        htmlToDraft(question.description).contentBlocks
      );
      return EditorState.createWithContent(contentState);
    });
  });

  const [questions, setQuestions] = useState(initialData?.questions || [{
    id: null,
    description: '',
    question_type: 'text',
    required: false,
    position: 0,
    options: [],
  }])

  const addQuestion = () => {
    setQuestions([
      ...questions,
      {
        id: null,
        description: '',
        question_type: 'text',
        required: false,
        position: questions.length,
        options: [],
      },
    ])
    setEditorStates([...editorStates, EditorState.createEmpty()])
  }

  const removeQuestion = (index) => {
    const newQuestions = questions.filter((_, i) => i !== index)
    setQuestions(newQuestions.map((q, i) => ({ ...q, position: i })))
    const newEditorStates = editorStates.filter((_, i) => i !== index)
    setEditorStates(newEditorStates)
  }

  const updateQuestion = (index, field, value) => {
    const newQuestions = [...questions]
    if (field === 'description') {
      const rawContentState = convertToRaw(value.getCurrentContent())
      const htmlContent = draftToHtml(rawContentState)
      newQuestions[index] = {
        ...newQuestions[index],
        description: htmlContent,
      }
      const newEditorStates = [...editorStates]
      newEditorStates[index] = value
      setEditorStates(newEditorStates)
    } else {
      newQuestions[index] = {
        ...newQuestions[index],
        [field]: value,
      }
    }

    // Initialize with one option if switching to a type that requires options
    if (field === 'question_type' &&
        ['single_selection', 'multiple_selection', 'dropdown'].includes(value) &&
        newQuestions[index].options.length === 0) {
      newQuestions[index].options = [{
        id: null,
        content: '',
        position: 0,
      }]
    }

    setQuestions(newQuestions)
  }

  const addOption = (questionIndex) => {
    const newQuestions = [...questions]
    newQuestions[questionIndex].options.push({
      id: null,
      content: '',
      position: newQuestions[questionIndex].options.length,
    })
    setQuestions(newQuestions)
  }

  const removeOption = (questionIndex, optionIndex) => {
    const newQuestions = [...questions]
    newQuestions[questionIndex].options = newQuestions[questionIndex].options
      .filter((_, i) => i !== optionIndex)
      .map((opt, i) => ({ ...opt, position: i }))
    setQuestions(newQuestions)
  }

  const updateOption = (questionIndex, optionIndex, content) => {
    const newQuestions = [...questions]
    newQuestions[questionIndex].options[optionIndex].content = content
    setQuestions(newQuestions)
  }

  const handleSubmit = (e) => {
    e.preventDefault()
    if (isSubmitting) return
    setIsSubmitting(true)
    onSubmit({ title, description, questions })
  }

  return (
    <form onSubmit={handleSubmit} className="survey-form">
      {!skip_header && (
        <div className="form-header">
          <div className="form-group">
            <label htmlFor="survey-title">Survey Title</label>
            <input
            id="survey-title"
            type="text"
            value={title}
            onChange={(e) => setTitle(e.target.value)}
            className="form-input"
          />
        </div>
        <div className="form-group">
          <label htmlFor="survey-description">Survey Description</label>
          <TextareaAutosize
            style={{ minHeight: 20 }}
            id="survey-description"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
            className="form-textarea"
          />
          </div>
        </div>
      )}

      {questions.map((question, questionIndex) => (
        <div key={questionIndex} className="question-card" style={{ marginBottom: '20px' }}>
          <div className="question-controls">
            <div className="form-group" style={{ marginBottom: '10px' }}>
              <Editor
                editorState={editorStates[questionIndex]}
                onEditorStateChange={(state) => updateQuestion(questionIndex, 'description', state)}
                toolbarClassName="survey-editor-toolbar"
                wrapperClassName="survey-editor-wrapper"
                editorClassName="survey-editor"
                editorStyle={{
                  height: 'auto',
                  minHeight: '36px',
                  maxHeight: '200px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  padding: '0px 8px',
                  overflow: 'hidden'
                }}
                toolbarStyle={{
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  marginBottom: '4px',
                  padding: '1px',
                  minHeight: '26px'
                }}
                toolbarCustomButtons={[]}
                toolbar={{
                  options: ['inline', 'list', 'link', 'fontSize', 'colorPicker'],
                  inline: {
                    options: ['bold', 'italic', 'underline'],
                    className: 'compact-toolbar-item',
                    dropdownClassName: 'compact-toolbar-dropdown'
                  },
                  list: {
                    options: ['unordered', 'ordered'],
                    className: 'compact-toolbar-item',
                    dropdownClassName: 'compact-toolbar-dropdown'
                  },
                  link: {
                    inDropdown: false,
                    showOpenOptionOnHover: true,
                    defaultTargetOption: '_blank',
                    options: ['link', 'unlink'],
                    className: 'compact-toolbar-item',
                    dropdownClassName: 'compact-toolbar-dropdown'
                  },
                  fontSize: {
                    options: [12, 14, 16, 18, 24]
                  },
                  colorPicker: {
                    colors: ['rgb(97,189,109)', 'rgb(26,188,156)', 'rgb(84,172,210)', 'rgb(44,130,201)',
                      'rgb(147,101,184)', 'rgb(71,85,119)', 'rgb(204,204,204)', 'rgb(65,168,95)',
                      'rgb(0,168,133)', 'rgb(61,142,185)', 'rgb(41,105,176)', 'rgb(85,57,130)',
                      'rgb(40,50,78)', 'rgb(0,0,0)',
                      'rgb(255,0,0)', 'rgb(255,153,0)', 'rgb(255,255,0)', 'rgb(0,255,0)',
                      'rgb(0,255,255)', 'rgb(0,0,255)', 'rgb(153,0,255)', 'rgb(255,0,255)',
                      'rgb(244,67,54)', 'rgb(233,30,99)', 'rgb(156,39,176)', 'rgb(103,58,183)',
                      'rgb(63,81,181)', 'rgb(33,150,243)', 'rgb(0,188,212)', 'rgb(0,150,136)',
                      'rgb(76,175,80)', 'rgb(139,195,74)', 'rgb(205,220,57)', 'rgb(255,235,59)',
                      'rgb(255,193,7)', 'rgb(255,152,0)', 'rgb(255,87,34)', 'rgb(121,85,72)'
                    ]
                  }
                }}
                placeholder={I18n.t('settings.booking_page.form.survey_input_placeholder')}
                stripPastedStyles={false}
                onContentStateChange={() => {
                  const editorElement = document.querySelector(`#question-${questionIndex} .survey-editor`);
                  if (editorElement) {
                    editorElement.style.height = 'auto';
                    const newHeight = Math.max(36, Math.min(200, editorElement.scrollHeight));
                    editorElement.style.height = `${newHeight}px`;
                  }
                }}
              />
            </div>

            <div className="form-group">
              <select
                id={`question-type-${questionIndex}`}
                value={question.question_type}
                onChange={(e) =>
                  updateQuestion(questionIndex, 'question_type', e.target.value)
                }
                className="form-select"
              >
                {Object.entries(QUESTION_TYPES).map(([value, label]) => (
                  <option key={value} value={value}>
                    {I18n.t(`settings.booking_page.form.survey_question_type_${value}`)}
                  </option>
                ))}
              </select>
            </div>
          </div>

          {['single_selection', 'multiple_selection', 'dropdown'].includes(
            question.question_type
          ) && (
            <div className="options-section">
              {question.options.map((option, optionIndex) => (
                <div key={optionIndex} className="option-item">
                  {question.question_type === 'single_selection' && (
                    <input type="radio" disabled className="mr-2" />
                  )}
                  {question.question_type === 'multiple_selection' && (
                    <input type="checkbox" disabled className="mr-2" />
                  )}
                  {question.question_type === 'dropdown' && (
                    <span className="mr-2 text-gray-500">{optionIndex + 1}.</span>
                  )}
                  <input
                    type="text"
                    value={option.content}
                    onChange={(e) =>
                      updateOption(questionIndex, optionIndex, e.target.value)
                    }
                    className="form-input"
                    placeholder={I18n.t('settings.booking_page.form.survey_option_placeholder', { index: optionIndex + 1 })}
                  />
                  <button
                    type="button"
                    className="btn btn-gray"
                    onClick={() => removeOption(questionIndex, optionIndex)}
                    title={I18n.t('settings.booking_page.form.survey_delete_option')}
                  >
                    ×
                  </button>
                </div>
              ))}
              <button
                type="button"
                className="btn btn-yellow"
                onClick={() => addOption(questionIndex)}
              >
                {I18n.t('settings.booking_page.form.survey_add_option')}
              </button>
            </div>
          )}

          {question.question_type === 'text' && (
            <div className="answer-preview mt-4">
              <TextareaAutosize
                disabled
                style={{ minHeight: 60 }}
                className="form-textarea text-gray-500"
                placeholder={I18n.t('settings.booking_page.form.survey_answer_placeholder')}
              />
            </div>
          )}

          <div className="form-group checkbox-group mt-6 pt-6 border-0 border-t border-gray-300 border-solid flex justify-right">
            <button
              type="button"
              className="btn btn-danger mx-6"
              onClick={() => removeQuestion(questionIndex)}
              title={I18n.t('settings.booking_page.form.survey_delete_question')}
            >
              <i className="fas fa-trash"></i>
            </button>

            <label>
              <input
                type="checkbox"
                checked={question.required}
                onChange={(e) =>
                  updateQuestion(questionIndex, 'required', e.target.checked)
                }
                className="form-checkbox"
              />
              {I18n.t('settings.booking_page.form.survey_required')}
            </label>
          </div>
        </div>
      ))}

      <div className="form-actions">
        <button
          type="button"
          className="btn btn-yellow mx-2"
          onClick={addQuestion}
        >
          {I18n.t('settings.booking_page.form.survey_add_question')}
        </button>
        <button
          type="submit"
          className="btn btn-tarco"
          disabled={isSubmitting}
        >
          {I18n.t('settings.booking_page.form.survey_save')}
        </button>
      </div>
    </form>
  )
}

export default SurveyBuilder