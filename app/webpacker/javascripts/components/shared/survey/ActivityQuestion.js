import React from 'react';
import moment from 'moment';
import { CustomTimePicker } from "shared/components";

const ActivityQuestion = ({ activities = [], onActivitiesChange }) => {
  const styles = {
    inputWithMessage: {
      position: 'relative',
    },
    helpText: {
      fontSize: '0.85em',
      color: '#666',
      marginTop: '4px',
    }
  };

  const addPeriod = () => {
    onActivitiesChange([
      ...activities,
      {
        id: null,
        name: '',
        datetime_slots: [{
          start_date: '',
          start_time: null,
          end_date: '',
          end_time: null
        }],
        max_participants: 10,
        price_cents: 0,
        position: activities.length,
      }
    ]);
  };

  const removePeriod = (index) => {
    if (activities.length <= 1) {
      return;
    }
    const newActivities = activities.filter((_, i) => i !== index);
    onActivitiesChange(newActivities.map((activity, i) => ({ ...activity, position: i })));
  };

  const updatePeriod = (index, field, value) => {
    const newActivities = [...activities];
    newActivities[index] = {
      ...newActivities[index],
      [field]: value
    };
    onActivitiesChange(newActivities);
  };

  React.useEffect(() => {
    if (activities.length === 0) {
      addPeriod();
    }
  }, []);

  const addDateTimeSlot = (periodIndex) => {
    const newActivities = [...activities];
    const currentPeriod = newActivities[periodIndex];
    const lastSlot = currentPeriod.datetime_slots[currentPeriod.datetime_slots.length - 1];

    // Use the last slot's values as defaults if available
    const newSlot = lastSlot ? {
      start_date: lastSlot.start_date,
      start_time: lastSlot.start_time,
      end_date: lastSlot.end_date,
      end_time: lastSlot.end_time
    } : {
      start_date: '',
      start_time: null,
      end_date: '',
      end_time: null
    };

    newActivities[periodIndex].datetime_slots.push(newSlot);
    onActivitiesChange(newActivities);
  };

  const removeDateTimeSlot = (periodIndex, slotIndex) => {
    const newActivities = [...activities];
    newActivities[periodIndex].datetime_slots = newActivities[periodIndex].datetime_slots.filter((_, i) => i !== slotIndex);
    onActivitiesChange(newActivities);
  };

  const updateDateTimeSlot = (periodIndex, slotIndex, field, value) => {
    const newActivities = [...activities];
    const currentSlot = newActivities[periodIndex].datetime_slots[slotIndex];

    // If updating start_date, check if end_date needs to be adjusted
    if (field === 'start_date') {
      const startDate = new Date(value);
      const endDate = currentSlot.end_date ? new Date(currentSlot.end_date) : null;

      // If end_date is empty or earlier than the new start_date, set it to the start_date
      if (!currentSlot.end_date || !endDate || endDate < startDate) {
        currentSlot.end_date = value;
      }
    }

    // Update the specified field
    currentSlot[field] = value;
    onActivitiesChange(newActivities);
  };

  return (
    <div className="activity-periods">
      {activities.map((period, index) => (
        <div key={index} className="activity-period">
          <div className="period-header">
            <div className="form-group period-name">
              <input
                type="text"
                value={period.name || ''}
                onChange={(e) => updatePeriod(index, 'name', e.target.value)}
                className="form-input"
                placeholder={I18n.t('settings.survey.period_name_placeholder')}
              />
              {period.id && (
                <p className="period-id mr-2">
                  {I18n.t('settings.survey.period_id')}: {String(period.id).padStart(3, '0')}
                </p>
              )}
              {activities.length > 1 && (
                <button
                  type="button"
                  className="btn btn-gray btn-symbol"
                  onClick={() => removePeriod(index)}
                  title={I18n.t('settings.survey.delete_period')}
                >
                  ×
                </button>
              )}
            </div>
          </div>
          <div className="period-content">
            <div className="datetime-slots">
              {period.datetime_slots?.map((slot, slotIndex) => (
                <div key={slotIndex} className="datetime-slot flex">
                  <div className="date-range">
                    <div className="form-group">
                      {slotIndex === 0 && (
                        <label>{I18n.t('settings.survey.start_date')}</label>
                      )}
                      <div className="datetime-inputs">
                        <input
                          type="date"
                          value={slot.start_date || ''}
                          onChange={(e) => updateDateTimeSlot(index, slotIndex, 'start_date', e.target.value)}
                          className="form-input date-input"
                        />
                        <CustomTimePicker
                          value={slot.start_time}
                          onChange={(time) => updateDateTimeSlot(index, slotIndex, 'start_time', time)}
                          name={`period_${index}_slot_${slotIndex}_start_time`}
                        />
                      </div>
                    </div>
                    <div className="form-group">
                      {slotIndex === 0 && (
                        <label>{I18n.t('settings.survey.end_date')}</label>
                      )}
                      <div className="datetime-inputs">
                        <input
                          type="date"
                          value={slot.end_date || ''}
                          onChange={(e) => updateDateTimeSlot(index, slotIndex, 'end_date', e.target.value)}
                          className="form-input date-input"
                        />
                        <CustomTimePicker
                          value={slot.end_time}
                          onChange={(time) => updateDateTimeSlot(index, slotIndex, 'end_time', time)}
                          name={`period_${index}_slot_${slotIndex}_end_time`}
                        />
                      </div>
                    </div>
                    {period.datetime_slots.length > 1 && (
                      <button
                        type="button"
                        className="btn btn-gray btn-symbol"
                        onClick={() => removeDateTimeSlot(index, slotIndex)}
                        title={I18n.t('settings.survey.delete_datetime_slot')}
                      >
                        ×
                      </button>
                    )}
                  </div>
                </div>
              ))}
              <button
                type="button"
                className="btn btn-yellow"
                onClick={() => addDateTimeSlot(index)}
              >
                <i className="fas fa-plus"></i> {I18n.t('settings.survey.add_datetime_slot')}
              </button>
            </div>
            <div className="participants-range">
              <div className="form-group">
                <label>{I18n.t('settings.survey.max_participants')}</label>
                <div className="input-with-message" style={styles.inputWithMessage}>
                  <input
                    type="number"
                    value={period.max_participants || ''}
                    onChange={(e) => updatePeriod(index, 'max_participants', parseInt(e.target.value) || 0)}
                    className="form-input"
                    placeholder={I18n.t('settings.survey.max_participants')}
                  />
                  {(!period.max_participants || period.max_participants === 0) && (
                    <div className="help-text" style={styles.helpText}>
                      {I18n.t('settings.survey.no_participants_range')}
                    </div>
                  )}
                </div>
              </div>
              <div className="form-group">
                <label>{I18n.t('settings.survey.price')}</label>
                <div className="input-with-message" style={styles.inputWithMessage}>
                  <input
                    type="number"
                    value={period.price_cents || ''}
                    onChange={(e) => updatePeriod(index, 'price_cents', parseInt(e.target.value) || 0)}
                    className="form-input"
                    placeholder={I18n.t('settings.survey.price')}
                    min="0"
                  />
                </div>
              </div>
            </div>
          </div>
        </div>
      ))}
      <button
        type="button"
        className="btn btn-yellow"
        onClick={addPeriod}
      >
        <i className="fas fa-plus"></i> {I18n.t('settings.survey.add_period')}
      </button>
    </div>
  );
};

export default ActivityQuestion;