"use strict";

import _ from "lodash";
import React from "react";
import moment from 'moment-timezone';

const composeValidators = (component, ...validators) => value =>
  validators.reduce((error, validator) => error || validator(component, value), undefined)

const requiredValidation = (key = "") => (component, value) => {
  if (component && (value === undefined || value === null || !String(value).length)) {
    return `${key}${component.props.i18n.errors.required}`
  }
  else {
    return undefined
  }
}

const emailPattern =  /^\w+([-+.']\w+)*@\w+([-.]\w+)*\.\w{2,}([-.]\w+)*$/u;
const emailFormatValidator = (component, value) => {
  if (!value) return undefined;

  return emailPattern.test(value) ? undefined : component.props.i18n.errors.invalid_email_format
}

const mustBeNumber = (component, value) => (isNaN(value) ? component.props.i18n.errors.not_a_number : undefined)

const lengthValidator = required_length => (component, value) => {
  if (!value) return undefined;

  return value.length === required_length ? undefined : component.props.i18n.errors.wrong_length.replace(/%{count}/, required_length)
}

const greaterEqualThan = (number, key="") => (component, value) => {
  if (!value) return undefined;

  return value >= number ? undefined : `${key}${component.props.i18n.errors.greater_than_or_equal_to.replace(/%{value}/, number)}`
}

const transformValues = values => {
  const data = {...values};

  // Move object boolean true/false value to string "true" or "false"
  Object.keys(data).forEach((key) => {
    if (isBoolean(data[key])) {
      data[key] = data[key] ? "true" : "false"
    }

    if (isNumber(data[key])) {
      data[key] = `${data[key]}`
    }
  })

  return data;
};

const isBoolean = val => "boolean" === typeof val;
const isNumber = val => "number" === typeof val;
const isString = val => "string" === typeof val;

const setProperListHeight = (component, adjustHeight) => {
  const listHeight = `${$(window).innerHeight() - adjustHeight} px`;

  component.setState({listHeight: listHeight})

  $(window).resize(() => {
    component.setState({listHeight: listHeight})
  });
}

const isWorkingDate = (schedules, date) => {
  return _.includes(schedules.working_dates, date.format("YYYY-MM-DD"));
};

const isHoliday = (schedules, date) => {
  return _.includes(schedules.holiday_dates, date.format("YYYY-MM-DD"));
};

const isReservedDate = (schedules, date) => {
  return _.includes(schedules.reservation_dates, date.format("YYYY-MM-DD"));
};

const isAvailableBookingDate = (schedules, date) => {
  return _.includes(schedules.available_booking_dates, date.format("YYYY-MM-DD"));
};

const isPersonalScheduleDate = (schedules, date) => {
  return _.includes(schedules.personal_schedule_dates, date.format("YYYY-MM-DD"));
};

const arrayWithLength = (size, default_value) => {
  return Array.from({length: size}, (v, i) => default_value)
}

const displayErrors = (form_values, error_reasons) => {
  let error_messages = [];
  let message_or_error_type = null
  let message_or_warning_type = null

  error_reasons.forEach((error_reason) => {
    ["errors", "warnings"].forEach((error_type) => {
      message_or_error_type = _.get(form_values[error_type], error_reason)

      if (typeof(message_or_error_type) === "object") {
        Object.keys(message_or_error_type).forEach((cause) => {
          if (cause) {
            error_messages.push(_displayErrors(form_values, [`${error_reason}${cause}`]))
          }
        })
      }
      else if (message_or_error_type) {
        error_messages.push(_displayErrors(form_values, [error_reason]))
      }
    })
  })

  return error_messages;
};

const _displayErrors = (form_values, error_reasons) => {
  let error_messages = [];
  let message = null;

  error_reasons.forEach((error_reason) => {
    if (message = _.get(form_values.warnings, error_reason)) {
      error_messages.push(<span className="warning" key={error_reason}>{message}</span>)
    }

    if (message = _.get(form_values.errors, error_reason)) {
      error_messages.push(<span className="danger" key={error_reason}>{message}</span>)
    }
  })

  return _.compact(error_messages);
};

// "%{key}foobar" => "valuefoobar"
const Translator = (template, options) => {
  Object.entries(options).forEach(([key, value]) => {
    template = template.replace(new RegExp('%?{' + key + '}' ,'g'), value)
  });

  return template
}

const zeroPad = (num, places) => String(num).padStart(places, '0')

const isValidHttpUrl = (string) => {
  let url;

  if (string === '') return true;

  try {
    url = new URL(string);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
}

const isValidLineUri = (string) => {
  let url;

  if (string === '') return true;

  if (string?.startsWith('tel:')) return true;

  try {
    url = new URL(string);
  } catch (_) {
    return false;
  }

  return url.protocol === "http:" || url.protocol === "https:";
}

const isValidLength= (string, length) => {
  return (string ?? "").length <= length;
}

const responseHandler = (error, response) => {
  if (error) {
    toastr.error(error.response.data.error_message)
  }
  else if (response.data.redirect_to) {
    window.location = response.data.redirect_to
  }
}

const currencyFormat = (number) => {
  return new Intl.NumberFormat().format(number)
}

const ticketExpireDate = (start_time, expire_month) => {
  return expire_month != 6 ? start_time.add(expire_month, "M").format("YYYY-MM-DD") : start_time.add(180, "d").format("YYYY-MM-DD")
}

// Map Rails locale codes to moment.js locale codes
const getMomentLocale = (appLocale = "tw") => {
  const localeMap = {
    'tw': 'zh-tw', // Map Rails "tw" to moment's "zh-tw"
    'ja': 'ja',    // Japanese uses the same code
    'en': 'en'     // English uses the same code
  };

  return localeMap[appLocale] || 'en'; // Default to English if locale not found
}

const getEditorLocale = (appLocale = "tw") => {
  const localeMap = {
    'tw': 'zh_tw', // Map Rails "tw" to moment's "zh_tw"
    'ja': 'ja'     // Japanese uses the same code
  };

  return localeMap[appLocale] || 'zh-TW'; // Default to zh-TW if locale not found
}

// Format activity slot date/time range for survey display
function formatActivitySlotRange(slot) {
  const startDateObj = slot.start_date ? new Date(slot.start_date) : null;
  const startDate = startDateObj ? moment(startDateObj).format('YYYY-MM-DD') : '';
  const startDay = startDateObj ? moment(startDateObj).format('dd') : '';
  const startTime = slot.start_time ? moment(slot.start_time, 'HH:mm:ss').format('HH:mm') : '';

  const endDateObj = slot.end_date ? new Date(slot.end_date) : null;
  const endDate = endDateObj ? moment(endDateObj).format('YYYY-MM-DD') : '';
  const endDay = endDateObj ? moment(endDateObj).format('dd') : '';
  const endTime = slot.end_time ? moment(slot.end_time, 'HH:mm:ss').format('HH:mm') : '';

  const start = startDate ? `${startDate} (${startDay}) ${startTime}` : '';
  let end = '';

  if (endDate) {
    if (startDate === endDate) {
      end = endTime;
    } else {
      end = `${endDate} (${endDay}) ${endTime}`;
    }
  }

  if (start || end) {
    return I18n.t('settings.survey.date_range', { start, end });
  } else {
    return '';
  }
}

// Convert YouTube and Vimeo URLs to embed format
const getEmbedUrl = (url) => {
  try {
    const urlObj = new URL(url);

    // Handle YouTube URLs
    if (urlObj.hostname.includes('youtube.com') || urlObj.hostname.includes('youtu.be')) {
      let videoId;

      if (urlObj.hostname.includes('youtube.com')) {
        // Handle youtube.com URLs
        const searchParams = new URLSearchParams(urlObj.search);
        videoId = searchParams.get('v');
      } else {
        // Handle youtu.be URLs
        videoId = urlObj.pathname.slice(1);
      }

      if (videoId) {
        return `https://www.youtube.com/embed/${videoId}`;
      }
    }

    // Handle Vimeo URLs
    if (urlObj.hostname.includes('vimeo.com')) {
      const videoId = urlObj.pathname.split('/').pop();
      if (videoId) {
        return `https://player.vimeo.com/video/${videoId}`;
      }
    }

    // Return original URL if not YouTube or Vimeo
    return url;
  } catch (e) {
    console.error('Error parsing URL:', e);
    return url;
  }
};

// Analyze existing special dates pattern and generate next suitable date/time
const generateNextSpecialDate = (existingDates) => {
  if (!existingDates || existingDates.length === 0) {
    // If no existing data, return default values
    const tomorrow = moment().add(1, 'day').format("YYYY-MM-DD");
    return {
      start_at_date_part: tomorrow,
      end_at_date_part: tomorrow,
      start_at_time_part: "09:00",
      end_at_time_part: "17:00"
    };
  }

  if (existingDates.length === 1) {
    // Only one record, copy time settings, add one day to date
    const lastDate = existingDates[0];
    const nextDate = moment(lastDate.start_at_date_part).add(1, 'day').format("YYYY-MM-DD");
    return {
      start_at_date_part: nextDate,
      end_at_date_part: nextDate,
      start_at_time_part: lastDate.start_at_time_part || "09:00",
      end_at_time_part: lastDate.end_at_time_part || "17:00"
    };
  }

  // Multiple records, analyze patterns
  const sortedDates = [...existingDates]
    .filter(date => date.start_at_date_part)
    .sort((a, b) => moment(a.start_at_date_part).diff(moment(b.start_at_date_part)));

  if (sortedDates.length >= 2) {
    const lastDate = sortedDates[sortedDates.length - 1];

    // Find actual date interval pattern, ignore duplicate entries on same day
    const uniqueDates = [];
    const seenDates = new Set();

    for (let i = sortedDates.length - 1; i >= 0; i--) {
      const dateStr = sortedDates[i].start_at_date_part;
      if (dateStr && !seenDates.has(dateStr)) {
        uniqueDates.unshift(sortedDates[i]);
        seenDates.add(dateStr);
      }
      if (uniqueDates.length >= 3) break; // We need at most 3 unique dates to analyze pattern
    }

    let nextDate;

    if (uniqueDates.length >= 2) {
      const lastUniqueDate = uniqueDates[uniqueDates.length - 1];
      const secondLastUniqueDate = uniqueDates[uniqueDates.length - 2];

      // Calculate actual date interval
      const daysDiff = moment(lastUniqueDate.start_at_date_part).diff(moment(secondLastUniqueDate.start_at_date_part), 'days');

      // Predict next date based on interval
      nextDate = moment(lastUniqueDate.start_at_date_part).add(daysDiff, 'days').format("YYYY-MM-DD");
    } else {
      // Only one unique date, default to add one day
      nextDate = moment(lastDate.start_at_date_part).add(1, 'day').format("YYYY-MM-DD");
    }

    // Check if times are consistent
    const timesConsistent = sortedDates.every(date =>
      date.start_at_time_part === lastDate.start_at_time_part &&
      date.end_at_time_part === lastDate.end_at_time_part
    );

    let predictedStartTime = "09:00";
    let predictedEndTime = "17:00";

    if (timesConsistent) {
      // All times are consistent, use same time
      predictedStartTime = lastDate.start_at_time_part;
      predictedEndTime = lastDate.end_at_time_part;
    } else {
      // Check for alternating patterns (works for 2 or more records)
      const timePattern = sortedDates.map(date => ({
        start: date.start_at_time_part,
        end: date.end_at_time_part
      }));

            // Check for cyclic patterns (can be 2, 3, or more time slots)
      const uniqueTimes = [...new Set(timePattern.map(t => `${t.start}-${t.end}`))];

      if (uniqueTimes.length >= 2 && uniqueDates.length >= uniqueTimes.length) {
        // Build the time pattern sequence from uniqueDates
        const timeSequence = uniqueDates.map(date => ({
          start: date.start_at_time_part,
          end: date.end_at_time_part,
          key: `${date.start_at_time_part}-${date.end_at_time_part}`
        }));

        // Try to detect the cycle length by finding repeating patterns
        let cycleLength = uniqueTimes.length;

        // Verify if the detected cycle length actually repeats
        let isValidCycle = true;
        if (timeSequence.length >= cycleLength * 2) {
          for (let i = 0; i < cycleLength && i < timeSequence.length - cycleLength; i++) {
            if (timeSequence[i].key !== timeSequence[i + cycleLength].key) {
              isValidCycle = false;
              break;
            }
          }
        }

        if (isValidCycle) {
          // Calculate which position in the cycle the next entry should be
          const currentPosition = (timeSequence.length) % cycleLength;

          if (currentPosition < timeSequence.length) {
            // Use the pattern from the cycle
            const nextPattern = timeSequence[currentPosition];
            predictedStartTime = nextPattern.start || "09:00";
            predictedEndTime = nextPattern.end || "17:00";
          } else {
            // Fallback to first pattern
            predictedStartTime = timeSequence[0].start || "09:00";
            predictedEndTime = timeSequence[0].end || "17:00";
          }
        } else {
          // Not a perfect cycle, try simple alternating
          const lastTimeKey = timeSequence[timeSequence.length - 1].key;
          const otherPattern = timeSequence.find(pattern => pattern.key !== lastTimeKey);

          if (otherPattern) {
            predictedStartTime = otherPattern.start || "09:00";
            predictedEndTime = otherPattern.end || "17:00";
          } else {
            predictedStartTime = timeSequence[0].start || "09:00";
            predictedEndTime = timeSequence[0].end || "17:00";
          }
        }
      } else if (sortedDates.length >= 3) {
        // Not a simple alternating pattern, check recent trends
        const thirdLastDate = sortedDates[sortedDates.length - 3];
        const secondLastDate = sortedDates[sortedDates.length - 2];
        // If third-to-last and last have same time, next might follow second-to-last
        if (thirdLastDate.start_at_time_part === lastDate.start_at_time_part) {
          predictedStartTime = secondLastDate.start_at_time_part || "09:00";
          predictedEndTime = secondLastDate.end_at_time_part || "17:00";
        } else {
          // Otherwise use the last time
          predictedStartTime = lastDate.start_at_time_part || "09:00";
          predictedEndTime = lastDate.end_at_time_part || "17:00";
        }
      } else {
        // Only two records with different times, alternate
        const secondLastDate = sortedDates[sortedDates.length - 2];
        predictedStartTime = secondLastDate.start_at_time_part || "09:00";
        predictedEndTime = secondLastDate.end_at_time_part || "17:00";
      }
    }

    return {
      start_at_date_part: nextDate,
      end_at_date_part: nextDate,
      start_at_time_part: predictedStartTime,
      end_at_time_part: predictedEndTime
    };
  }

  // Fallback option
  const lastDate = existingDates[existingDates.length - 1];
  const nextDate = moment(lastDate.start_at_date_part).add(1, 'day').format("YYYY-MM-DD");
  return {
    start_at_date_part: nextDate,
    end_at_date_part: nextDate,
    start_at_time_part: lastDate.start_at_time_part || "09:00",
    end_at_time_part: lastDate.end_at_time_part || "17:00"
  };
};

export {
  requiredValidation,
  emailFormatValidator,
  transformValues,
  composeValidators,
  lengthValidator,
  mustBeNumber,
  greaterEqualThan,
  setProperListHeight,
  isWorkingDate,
  isHoliday,
  isReservedDate,
  isAvailableBookingDate,
  isPersonalScheduleDate,
  arrayWithLength,
  displayErrors,
  Translator,
  zeroPad,
  isValidHttpUrl,
  isValidLineUri,
  isValidLength,
  responseHandler,
  currencyFormat,
  ticketExpireDate,
  getMomentLocale,
  formatActivitySlotRange,
  getEmbedUrl,
  getEditorLocale,
  generateNextSpecialDate,
};
