import React, { useState, useEffect } from 'react'
import TextareaAutosize from 'react-autosize-textarea';
import { Editor } from 'react-draft-wysiwyg';
import { EditorState, ContentState, convertToRaw } from 'draft-js';
import draftToHtml from 'draftjs-to-html';
import htmlToDraft from 'html-to-draftjs';
import ActivityQuestion from './ActivityQuestion';
import { getEmbedUrl, getEditorLocale } from 'libraries/helper';

const QUESTION_TYPES = {
  text: 'Text',
  single_selection: 'Single Selection',
  multiple_selection: 'Multiple Selection',
  dropdown: 'Dropdown',
  activity: 'Activity',
  empty_block: 'Empty Block'
}

const SurveyBuilder = ({
  onSubmit,
  initialData = {},
  skip_header = false,
  onTitleChange = () => {},
  onDescriptionChange = () => {},
  onQuestionsChange = () => {},
  business_owner_id = null,
  currency = 'JPY',
  mode = 'survey'
}) => {
  const [title, setTitle] = useState(initialData?.title || '');
  const [description, setDescription] = useState(initialData?.description || '');
  const [descriptionEditorState, setDescriptionEditorState] = useState(() => {
    if (!initialData?.description) {
      return EditorState.createEmpty();
    }
    const contentState = ContentState.createFromBlockArray(
      htmlToDraft(initialData.description).contentBlocks
    );
    return EditorState.createWithContent(contentState);
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [questions, setQuestions] = useState(() => {
    if (initialData?.questions && initialData.questions.length > 0) {
      return initialData.questions;
    }
    if (mode === 'activity') {
      return [{
        id: null,
        description: '',
        question_type: 'activity',
        required: true,
        position: 0,
        options: [],
        activities: []
      }];
    }
    return [{
      id: null,
      description: '',
      question_type: 'text',
      required: false,
      position: 0,
      options: [],
      activities: []
    }];
  });

  const [editorStates, setEditorStates] = useState(() => {
    const initialQuestions = initialData?.questions || [{
            id: null,
            description: '',
            question_type: 'text',
            required: false,
            position: 0,
            options: [],
            activities: []
    }];

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

  // Handle title change
  const handleTitleChange = (e) => {
    const newTitle = e.target.value;
    setTitle(newTitle);
    if (onTitleChange) {
      onTitleChange(newTitle);
    }
  };

  // Handle description change
  const handleDescriptionChange = (editorState) => {
    setDescriptionEditorState(editorState);
    const rawContentState = convertToRaw(editorState.getCurrentContent());
    const htmlContent = draftToHtml(rawContentState);
    setDescription(htmlContent);
    if (onDescriptionChange) {
      onDescriptionChange(htmlContent);
    }
  };

  const addQuestion = (type) => {
    // Check if trying to add activity question when one already exists
    if (type === 'activity' && questions.some(q => q.question_type === 'activity')) {
      alert(I18n.t('settings.survey.only_one_activity_allowed'));
      return;
    }

    const newQuestion = {
      id: null,
      description: '',
      question_type: type,
      required: type === 'activity' ? true : false,
      position: questions.length,
      options: [],
      activities: []
    };

    setQuestions(prevQuestions => {
      const newQuestions = [...prevQuestions, newQuestion];
      if (onQuestionsChange) {
        onQuestionsChange(newQuestions);
      }
      return newQuestions;
    });
    setEditorStates(prev => [...prev, EditorState.createEmpty()]);
  };

  const removeQuestion = (index) => {
    setQuestions(prevQuestions => {
      const newQuestions = prevQuestions
        .filter((_, i) => i !== index)
        .map((q, i) => ({ ...q, position: i }));
      if (onQuestionsChange) {
        onQuestionsChange(newQuestions);
      }
      return newQuestions;
    });
    setEditorStates(prev => prev.filter((_, i) => i !== index));
  };

  const updateQuestion = (index, field, value) => {
    setQuestions(prevQuestions => {
      const newQuestions = [...prevQuestions];

      if (field === 'question_type') {
        // Check if trying to change to activity type when one already exists
        if (value === 'activity' && prevQuestions.some(q => q.question_type === 'activity')) {
          alert(I18n.t('settings.survey.only_one_activity_allowed'));
          return prevQuestions;
        }

        // Initialize new question type options
        newQuestions[index] = {
          ...newQuestions[index],
          [field]: value,
          options: [],
          activities: [],
          required: value === 'activity' ? true : newQuestions[index].required
        };

        // Set initial options based on question type
        switch (value) {
          case 'single_selection':
          case 'multiple_selection':
          case 'dropdown':
            newQuestions[index].options = [{
              id: null,
              content: '',
              position: 0,
            }];
            break;
          case 'activity':
            newQuestions[index].activities = [{
              id: null,
              name: '',
              position: 0,
              max_participants: null,
              price_cents: 0,
              datetime_slots: [{
                start_date: '',
                start_time: null,
                end_date: '',
                end_time: null
              }]
            }];
            break;
          default:
            // text type doesn't need options or activities
            break;
        }
      } else if (field === 'options') {
        newQuestions[index].options = value;
      } else if (field === 'activities') {
        newQuestions[index].activities = value;
      } else if (field === 'description') {
        const rawContentState = convertToRaw(value.getCurrentContent());
        const htmlContent = draftToHtml(rawContentState);
        newQuestions[index] = {
          ...newQuestions[index],
          description: htmlContent,
        };
        const newEditorStates = [...editorStates];
        newEditorStates[index] = value;
        setEditorStates(newEditorStates);
      } else {
        newQuestions[index] = {
          ...newQuestions[index],
          [field]: value,
        };
      }

      if (onQuestionsChange) {
        onQuestionsChange(newQuestions);
      }
      return newQuestions;
    });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    if (isSubmitting) return;
    setIsSubmitting(true);
    try {
      const formData = {
        id: initialData.id,
        title,
        description,
        questions: questions.map(q => ({
          ...q,
          activities: q.activities?.map(activity => ({
            ...activity,
            datetime_slots: activity.datetime_slots?.map(slot => ({
              ...slot,
              start_time: slot.start_time || null,
              end_time: slot.end_time || null
            }))
          }))
        }))
      };
      if (onSubmit) {
        await onSubmit(formData);
      }
    } finally {
      setIsSubmitting(false);
    }
  };

  // Handle image upload
  const uploadCallback = (file) => {
    return new Promise((resolve, reject) => {
      const formData = new FormData();
      formData.append('image', file);

      fetch('/api/images', {
        method: 'POST',
        headers: {
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').content
        },
        body: formData
      })
      .then(response => response.json())
      .then(result => {
        if (result.success) {
          resolve(result);
        } else {
          reject(new Error(result.message || 'Upload failed'));
        }
      })
      .catch(error => {
        console.error('Error uploading image:', error);
        reject(error);
      });
    });
  };

  return (
    <form onSubmit={handleSubmit} className="survey-form">
      {!skip_header && (
        <div className="form-header">
          <div className="form-group">
            <label htmlFor="survey-title">{I18n.t('settings.survey.title')}</label>
            <input
              id="survey-title"
              type="text"
              value={title}
              onChange={handleTitleChange}
              className="form-input"
            />
          </div>
          <div className="form-group">
            <label htmlFor="survey-description">{I18n.t('settings.survey.description')}</label>
            <Editor
              editorState={descriptionEditorState}
              placeholder={I18n.t('user_bot.dashboards.surveys.description_desc')}
              onEditorStateChange={handleDescriptionChange}
              editorStyle={{
                height: 'auto',
                minHeight: '100px',
                border: '1px solid #ddd',
                borderRadius: '4px',
                padding: '0px 8px',
                overflow: 'hidden'
              }}
              toolbarStyle={{
                border: '0px',
                borderRadius: '4px',
                marginBottom: '4px',
                padding: '1px',
                minHeight: '26px'
              }}
              editorClassName="survey-editor"
              wrapperClassName="survey-editor-wrapper"
              toolbarClassName="survey-editor-toolbar"
              toolbar={{
                options: ['inline', 'list', 'link', 'image', 'embedded'],
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
                embedded: {
                  className: 'compact-toolbar-item',
                  dropdownClassName: 'compact-toolbar-dropdown',
                  defaultSize: {
                    height: 'auto',
                    width: 'auto'
                  },
                  embedCallback: (url) => {
                    return getEmbedUrl(url);
                  }
                },
                image: {
                  uploadCallback: uploadCallback,
                  alt: { present: true, mandatory: false },
                  previewImage: true,
                  inputAccept: 'image/gif,image/jpeg,image/jpg,image/png,image/svg',
                  className: 'compact-toolbar-item',
                  dropdownClassName: 'compact-toolbar-dropdown'
                }
              }}
              localization={{
                locale: getEditorLocale(I18n.locale),
              }}
            />
          </div>
        </div>
      )}

      {questions.map((question, questionIndex) => (
        <div key={questionIndex} className="question-card">
          <div className="question-controls">
            <div className="form-group">
              <select
                value={question.question_type}
                onChange={(e) => updateQuestion(questionIndex, 'question_type', e.target.value)}
                className="form-select"
              >
                {Object.entries(QUESTION_TYPES)
                  .filter(([value]) => mode === 'activity' || value !== 'activity')
                  .map(([value, label]) => (
                    <option key={value} value={value}>
                      {I18n.t(`settings.survey.question_type_${value}`)}
                    </option>
                  ))}
              </select>
            </div>

            <div className="form-group">
              <Editor
                editorState={editorStates[questionIndex]}
                placeholder={I18n.t('user_bot.dashboards.surveys.question_desc')}
                onEditorStateChange={(state) => updateQuestion(questionIndex, 'description', state)}
                editorStyle={{
                  height: 'auto',
                  minHeight: '100px',
                  border: '1px solid #ddd',
                  borderRadius: '4px',
                  padding: '0px 8px',
                  overflow: 'hidden'
                }}
                toolbarStyle={{
                  border: '0px',
                  borderRadius: '4px',
                  marginBottom: '4px',
                  padding: '1px',
                  minHeight: '26px'
                }}
                editorClassName="survey-editor"
                wrapperClassName="survey-editor-wrapper"
                toolbarClassName="survey-editor-toolbar"
                toolbar={{
                  options: ['inline', 'list', 'link', 'image'],
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
                  image: {
                    uploadCallback: uploadCallback,
                    alt: { present: true, mandatory: false },
                    previewImage: true,
                    inputAccept: 'image/gif,image/jpeg,image/jpg,image/png,image/svg',
                    className: 'compact-toolbar-item',
                    dropdownClassName: 'compact-toolbar-dropdown'
                  }
                }}
                localization={{
                  locale: getEditorLocale(I18n.locale),
                }}
              />
            </div>

          </div>

          {question.question_type === 'activity' && (
            <ActivityQuestion
              activities={question.activities}
              onActivitiesChange={(newActivities) => {
                updateQuestion(questionIndex, 'activities', newActivities);
              }}
            />
          )}

          {['single_selection', 'multiple_selection', 'dropdown'].includes(question.question_type) && (
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
                    onChange={(e) => {
                      const newQuestions = [...questions];
                      newQuestions[questionIndex].options[optionIndex].content = e.target.value;
                      setQuestions(newQuestions);
                      if (onQuestionsChange) {
                        onQuestionsChange(newQuestions);
                      }
                    }}
                    className="form-input"
                    placeholder={I18n.t('settings.survey.option_placeholder', { index: optionIndex + 1 })}
                  />
                  <button
                    type="button"
                    className="btn btn-gray"
                    onClick={() => {
                      const newQuestions = [...questions];
                      newQuestions[questionIndex].options = newQuestions[questionIndex].options
                        .filter((_, i) => i !== optionIndex)
                        .map((opt, i) => ({ ...opt, position: i }));
                      setQuestions(newQuestions);
                      if (onQuestionsChange) {
                        onQuestionsChange(newQuestions);
                      }
                    }}
                  >
                    ×
                  </button>
                </div>
              ))}
              <button
                type="button"
                className="btn btn-yellow"
                onClick={() => {
                  const newQuestions = [...questions];
                  newQuestions[questionIndex].options.push({
                    id: null,
                    content: '',
                    position: newQuestions[questionIndex].options.length,
                  });
                  setQuestions(newQuestions);
                  if (onQuestionsChange) {
                    onQuestionsChange(newQuestions);
                  }
                }}
              >
                <i className="fas fa-plus"></i> {I18n.t('settings.survey.add_option')}
              </button>
            </div>
          )}

          {question.question_type === 'text' && (
            <div className="answer-preview">
              <TextareaAutosize
                style={{ minHeight: 60 }}
                disabled
                className="form-textarea text-gray-500"
                placeholder={I18n.t('settings.survey.answer_placeholder')}
              />
            </div>
          )}

          <div className="form-group checkbox-group">
            <label>
              <input
                type="checkbox"
                checked={question.required}
                onChange={(e) => updateQuestion(questionIndex, 'required', e.target.checked)}
                className="form-checkbox"
              />
              {I18n.t('settings.survey.required')}
            </label>

            <button
              type="button"
              className="btn btn-danger"
              onClick={() => removeQuestion(questionIndex)}
            >
              <i className="fas fa-trash"></i>
            </button>
          </div>
        </div>
      ))}

      <div className="form-actions">
        <button
          type="button"
          className="btn btn-yellow mr-2"
          onClick={() => addQuestion('text')}
        >
          <i className="fas fa-plus"></i> {I18n.t('settings.survey.add_question')}
        </button>

        <button
          type="submit"
          className="btn btn-tarco"
          disabled={isSubmitting}
        >
          {I18n.t('settings.survey.save')}
        </button>
      </div>
    </form>
  );
};

export default SurveyBuilder;
