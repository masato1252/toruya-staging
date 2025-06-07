import React, { useState, useEffect } from "react";
import { Calendar, momentLocalizer, Views } from 'react-big-calendar'
import moment from 'moment-timezone'
import 'moment/locale/ja' // Import Japanese language pack
import 'moment/locale/zh-tw' // Import Traditional Chinese language pack
import Routes from 'js-routes.js'
import I18n from 'i18n-js/index.js.erb'
import { getMomentLocale } from 'libraries/helper.js'

// Set moment's language and timezone
const setMomentLocaleAndTimezone = (timezone) => {
  const currentLocale = I18n.locale || I18n.defaultLocale;

  // Use unified helper function to get moment locale
  const momentLocale = getMomentLocale(currentLocale);
  moment.locale(momentLocale);

  // Set default timezone
  if (timezone) {
    moment.tz.setDefault(timezone);
    console.log(`📅 Calendar timezone set to: ${timezone}`);
  }

  console.log(`📅 Calendar locale set to: ${momentLocale} (from Rails locale: ${currentLocale})`);
};

// Initialize language and timezone during setup (using default values temporarily, will be reset based on props in component)
setMomentLocaleAndTimezone();

const localizer = momentLocalizer(moment)

// Custom calendar text translations
const getCalendarMessages = () => {
  const currentLocale = I18n.locale || I18n.defaultLocale;

  switch (currentLocale) {
    case 'ja':
      return {
        allDay: '終日',
        previous: '前',
        next: '次',
        today: '今日',
        month: '月',
        week: '週',
        day: '日',
        agenda: 'アジェンダ',
        date: '日付',
        time: '時間',
        event: 'イベント',
        noEventsInRange: 'この期間にはイベントがありません',
        showMore: total => `+ ${total} 件以上`
      };
    case 'tw':
      return {
        allDay: '全天',
        previous: '上一個',
        next: '下一個',
        today: '今天',
        month: '月',
        week: '週',
        day: '日',
        agenda: '議程',
        date: '日期',
        time: '時間',
        event: '事件',
        noEventsInRange: '此期間沒有事件',
        showMore: total => `+ ${total} 個以上`
      };
    default:
      // English (default)
      return {
        allDay: 'All Day',
        previous: 'Back',
        next: 'Next',
        today: 'Today',
        month: 'Month',
        week: 'Week',
        day: 'Day',
        agenda: 'Agenda',
        date: 'Date',
        time: 'Time',
        event: 'Event',
        noEventsInRange: 'There are no events in this range.',
        showMore: total => `+${total} more`
      };
  }
};

// Update off-date-modal datetime values
const updateOffDateModalValues = (selectedDate, selectedTime, timezone = null) => {
  console.log('🕐 Updating off-date-modal with:', { selectedDate, selectedTime, timezone });

  // Wait for modal to fully load
  setTimeout(() => {
    // Try multiple selector strategies to find the inputs
    const startDateInput =
      document.querySelector('#off-date-modal input[name="custom_schedules[][start_time_date_part]"]') ||
      document.querySelector('#off-date-modal input[name*="start_time_date_part"]') ||
      document.querySelector('#off-date-modal [name*="start_time_date_part"]');

    const startTimeInput =
      document.querySelector('#off-date-modal input[name="custom_schedules[][start_time_time_part]"]') ||
      document.querySelector('#off-date-modal input[name*="start_time_time_part"]') ||
      document.querySelector('#off-date-modal [name*="start_time_time_part"]');

    const endDateInput =
      document.querySelector('#off-date-modal input[name="custom_schedules[][end_time_date_part]"]') ||
      document.querySelector('#off-date-modal input[name*="end_time_date_part"]') ||
      document.querySelector('#off-date-modal [name*="end_time_date_part"]');

    const endTimeInput =
      document.querySelector('#off-date-modal input[name="custom_schedules[][end_time_time_part]"]') ||
      document.querySelector('#off-date-modal input[name*="end_time_time_part"]') ||
      document.querySelector('#off-date-modal [name*="end_time_time_part"]');

    console.log('🔍 Found modal inputs:', {
      startDate: !!startDateInput,
      startTime: !!startTimeInput,
      endDate: !!endDateInput,
      endTime: !!endTimeInput
    });

    const updateInput = (input, value, label) => {
      if (input) {
        input.value = value;
        // Trigger multiple events to ensure React/Rails forms pick up the change
        ['input', 'change', 'blur', 'focus'].forEach(eventType => {
          input.dispatchEvent(new Event(eventType, { bubbles: true }));
        });
        console.log(`✅ Updated ${label} to:`, input.value);
      } else {
        console.error(`❌ ${label} input not found`);
      }
    };

    // Update each input field
    updateInput(startDateInput, selectedDate, 'start date');
    updateInput(startTimeInput, selectedTime, 'start time');
    updateInput(endDateInput, selectedDate, 'end date');

    // Calculate end time: if 00:00, set to 23:59 (all day), otherwise add 1 hour
        const endTime = selectedTime === '00:00' ? '23:59' :
      moment(selectedTime, 'HH:mm').add(1, 'hour').format('HH:mm');

    updateInput(endTimeInput, endTime, 'end time');
  }, 300); // Reduced timeout to be more responsive
};

// Global listener for off-date-modal open event
$(document).ready(function() {
  $(document).on('show.bs.modal', '#off-date-modal', function() {
    console.log('🔔 off-date-modal opening, checking for stored date/time');
    if (window.selectedCalendarDateTime) {
      console.log('📅 Found stored date/time:', window.selectedCalendarDateTime);
      updateOffDateModalValues(
        window.selectedCalendarDateTime.date,
        window.selectedCalendarDateTime.time,
        window.selectedCalendarDateTime.timezone
      );
    } else {
      console.warn('⚠️ No stored calendar date/time found');
    }
  });

  // Also listen for 'shown.bs.modal' in case 'show.bs.modal' doesn't work
  $(document).on('shown.bs.modal', '#off-date-modal', function() {
    console.log('🔔 off-date-modal shown, double-checking date/time update');
    if (window.selectedCalendarDateTime) {
      setTimeout(() => {
        updateOffDateModalValues(
          window.selectedCalendarDateTime.date,
          window.selectedCalendarDateTime.time,
          window.selectedCalendarDateTime.timezone
        );
      }, 100);
    }
  });
});

const SchedulesCalendar = ({ props }) => {
  const { schedules: initialSchedules, business_owner_id, reservations_approval_flow, _from, queried_start_date, queried_end_date, timezone, month_date } = props;

  // State management
  const [schedules, setSchedules] = useState(initialSchedules);
  const [queriedStartDate, setQueriedStartDate] = useState(queried_start_date);
  const [queriedEndDate, setQueriedEndDate] = useState(queried_end_date);
  const [isLoading, setIsLoading] = useState(false);
  const [calendarKey, setCalendarKey] = useState(0);

  // Initialization debug info
  useEffect(() => {
    console.log('📅 Calendar initialized with:');
    console.log('   Initial schedules count:', initialSchedules?.length || 0);
    console.log('   Initial date range:', queried_start_date, 'to', queried_end_date);
    console.log('   Business owner ID:', business_owner_id);
    console.log('   Timezone:', timezone);

    // Ensure language and timezone settings are correct
    setMomentLocaleAndTimezone(timezone);
  }, [timezone]);

  // Listen for language changes
  useEffect(() => {
    setMomentLocaleAndTimezone(timezone);
  }, [I18n.locale, timezone]);

  // Force calendar re-render to fix CSS issues on initial load
  useEffect(() => {
    const timer = setTimeout(() => {
      setCalendarKey(prev => prev + 1);
    }, 100);
    return () => clearTimeout(timer);
  }, []);

    // Convert time strings to Date objects using correct timezone
  const convertedSchedules = schedules.map(schedule => {
    // Debug: log original time strings
    console.log('🕐 Original times for schedule:', schedule.id || schedule.title, {
      full_start_time: schedule.full_start_time,
      full_end_time: schedule.full_end_time,
      timezone: timezone
    });

        // Check if time string already contains timezone info (ends with +XX:XX or -XX:XX)
    const hasTimezone = /[+-]\d{2}:\d{2}$/.test(schedule.full_start_time);

    const startTime = hasTimezone ?
      moment(schedule.full_start_time).toDate() :
      (timezone ? moment.tz(schedule.full_start_time, timezone).toDate() : moment(schedule.full_start_time).toDate());

    const endTime = hasTimezone ?
      moment(schedule.full_end_time).toDate() :
      (timezone ? moment.tz(schedule.full_end_time, timezone).toDate() : moment(schedule.full_end_time).toDate());

    // Debug: log converted times
    console.log('🕐 Converted times:', {
      hasTimezone: hasTimezone,
      start: startTime.toISOString(),
      end: endTime.toISOString(),
      startLocal: startTime.toLocaleString(),
      endLocal: endTime.toLocaleString(),
      startHour: startTime.getHours(),
      startMinute: startTime.getMinutes()
    });

    return {
      ...schedule,
      start: startTime,
      end: endTime
    };
  });

  // Fetch new event data
  const fetchEvents = async (startDate, endDate) => {
    console.log('🚀 Starting to fetch events for range:', startDate, 'to', endDate);
    setIsLoading(true);
    try {
      const params = new URLSearchParams({
        schedule_start_date: startDate,
        schedule_end_date: endDate
      });

      const url = `${Routes.events_lines_user_bot_schedules_path(business_owner_id)}?${params}`;
      console.log('📡 Fetching from URL:', url);

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'application/json'
        }
      });

      console.log('📡 Response status:', response.status, response.statusText);

      if (response.ok) {
        const newEvents = await response.json();
        console.log('📊 Received', newEvents.length, 'events');

        // Merge new events with existing events, avoiding duplicates
        setSchedules(prevSchedules => {
          const existingIds = prevSchedules.map(s => `${s.type}-${s.id}`);
          const newUniqueEvents = newEvents.filter(s => !existingIds.includes(`${s.type}-${s.id}`));
          return [...prevSchedules, ...newUniqueEvents];
        });

        // Expand queried date range instead of replacing
        setQueriedStartDate(prevStart => {
          const newStart = moment(startDate).isBefore(moment(prevStart)) ? startDate : prevStart;
          console.log('📅 Updated queriedStartDate from', prevStart, 'to', newStart);
          return newStart;
        });

        setQueriedEndDate(prevEnd => {
          const newEnd = moment(endDate).isAfter(moment(prevEnd)) ? endDate : prevEnd;
          console.log('📅 Updated queriedEndDate from', prevEnd, 'to', newEnd);
          return newEnd;
        });

        console.log('✅ Successfully merged new events and expanded date range');
      } else {
        console.error('❌ Failed to fetch events:', response.status, response.statusText);
      }
    } catch (error) {
      console.error('❌ Error fetching events:', error);
    } finally {
      setIsLoading(false);
      console.log('🏁 Finished fetching events');
    }
  };

  // Handle calendar navigation
  const handleNavigate = (newDate, view, action) => {
    console.log('🔄 Calendar navigated to:', newDate, 'view:', view, 'action:', action);
    console.log('📅 Current queried range:', queriedStartDate, 'to', queriedEndDate);

    // Calculate required date range based on view
    let requiredStartDate, requiredEndDate;

    if (view === 'month') {
      requiredStartDate = moment(newDate).startOf('month').format('YYYY-MM-DD');
      requiredEndDate = moment(newDate).endOf('month').format('YYYY-MM-DD');
    } else if (view === 'week') {
      requiredStartDate = moment(newDate).startOf('week').format('YYYY-MM-DD');
      requiredEndDate = moment(newDate).endOf('week').format('YYYY-MM-DD');
    } else if (view === 'day') {
      requiredStartDate = moment(newDate).format('YYYY-MM-DD');
      requiredEndDate = moment(newDate).format('YYYY-MM-DD');
    } else {
      // Default to month view
      requiredStartDate = moment(newDate).startOf('month').format('YYYY-MM-DD');
      requiredEndDate = moment(newDate).endOf('month').format('YYYY-MM-DD');
    }

    console.log('📍 Required range:', requiredStartDate, 'to', requiredEndDate);

    // Check if need to fetch new data
    const currentStart = moment(queriedStartDate);
    const currentEnd = moment(queriedEndDate);
    const needStart = moment(requiredStartDate);
    const needEnd = moment(requiredEndDate);

    console.log('🔍 Checking if need to fetch new data...');
    console.log('   Need start:', requiredStartDate, 'is before current start:', queriedStartDate, '?', needStart.isBefore(currentStart));
    console.log('   Need end:', requiredEndDate, 'is after current end:', queriedEndDate, '?', needEnd.isAfter(currentEnd));

    if (needStart.isBefore(currentStart) || needEnd.isAfter(currentEnd)) {
      console.log('✅ Fetching new data for range:', requiredStartDate, 'to', requiredEndDate);
      fetchEvents(requiredStartDate, requiredEndDate);
    } else {
      console.log('❌ No need to fetch new data, current range covers required range');
    }
  };

  // Set colors based on event type and status
  const eventStyleGetter = (event) => {
    let backgroundColor, borderColor, color;

    if (event.type === 'reservation') {
      switch (event.aasm_state || event.state) {
        case 'reserved':
          backgroundColor = '#28a745';
          borderColor = '#1e7e34';
          color = 'white';
          break;
        case 'pending':
          backgroundColor = '#ca4e0e';
          borderColor = '#b0450d';
          color = 'white';
          break;
        case 'checked_in':
          backgroundColor = '#fcbe46';
          borderColor = '#e6a21f';
          color = 'black';
          break;
        case 'checked_out':
        case 'canceled':
          backgroundColor = '#9D9D9D';
          borderColor = '#888';
          color = 'white';
          break;
        case 'noshow':
          backgroundColor = '#aecfc8';
          borderColor = '#84b3aa';
          color = 'black';
          break;
        default:
          backgroundColor = '#28a745';
          borderColor = '#1e7e34';
          color = 'white';
      }
    } else {
      switch (event.type) {
        case 'booking_page_holder_schedule':
          backgroundColor = '#ffc107';
          borderColor = '#d39e00';
          color = 'black';
          break;
        case 'off_schedule':
          backgroundColor = 'white'
          borderColor = '#b3b3b3';
          color = 'black';
          break;
        case 'open_schedule':
          backgroundColor = '#17a2b8';
          borderColor = '#138496';
          color = 'white';
          break;
        default:
          backgroundColor = '#6c757d';
          borderColor = '#545b62';
          color = 'white';
      }
    }

    return {
      style: {
        backgroundColor,
        borderColor,
        color,
        borderWidth: '1px',
        borderStyle: 'solid'
      }
    };
  };

    // Handle event click
  const handleSelectEvent = (event, e) => {
    console.log('🎯 Event clicked:', event);
    console.log('🎯 Event details:', {
      type: event.type,
      id: event.id,
      title: event.title || event.description,
      start: event.start,
      end: event.end
    });

    // Stop propagation to prevent slot selection
    if (e && e.stopPropagation) {
      e.stopPropagation();
      console.log('🛑 Stopped event propagation');
    }
    if (event.type === 'reservation') {
      const modalUrl = Routes.lines_user_bot_shop_reservation_path(business_owner_id, event.shop.id, event.id, {
        reservations_approval_flow: reservations_approval_flow,
        _from: _from
      });

      fetch(modalUrl, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html'
        }
      })
      .then(response => response.text())
      .then(html => {
        const modalElement = document.querySelector('#dummyModal');
        if (modalElement) {
          modalElement.innerHTML = html;
          $('#dummyModal').modal('show');
        }
      })
      .catch(error => {
          console.error('❌ Error loading reservation modal:', error);
      });
    } else if (event.type === 'booking_page_holder_schedule') {
      // Dynamically load booking_page_special_date modal
      const modalUrl = Routes.lines_user_bot_booking_page_special_date_path(business_owner_id, event.id);

      fetch(modalUrl, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html'
        }
      })
      .then(response => response.text())
      .then(html => {
        const modalElement = document.querySelector('#dummyModal');
        if (modalElement) {
          modalElement.innerHTML = html;

          // Re-scan and mount React components
          if (window.ReactRailsUJS) {
            window.ReactRailsUJS.mountComponents(modalElement);
          }

          $('#dummyModal').modal('show');
        }
      })
      .catch(error => {
          console.error('❌ Error loading booking page holder modal:', error);
      });
    } else {
      // Dynamically load custom_schedule modal (off_schedule or open_schedule)
      const modalUrl = Routes.lines_user_bot_custom_schedule_path(business_owner_id, event.id);

      fetch(modalUrl, {
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': 'text/html'
        }
      })
      .then(response => response.text())
      .then(html => {
        const modalElement = document.querySelector('#dummyModal');
        if (modalElement) {
          modalElement.innerHTML = html;

          // Re-scan and mount React components
          if (window.ReactRailsUJS) {
            window.ReactRailsUJS.mountComponents(modalElement);
          }

          $('#dummyModal').modal('show');
        }
      })
      .catch(error => {
          console.error('❌ Error loading custom schedule modal:', error);
      });
    }
  };

    // Handle clicking empty time slot to add schedule
  const handleSelectSlot = (slotInfo, e) => {
    console.log('🎯🎯🎯 SLOT SELECTED! handleSelectSlot called by react-big-calendar:', slotInfo);
    console.log('🎯 RBC-provided start:', slotInfo.start.toISOString());
    console.log('🎯 RBC-provided end:', slotInfo.end.toISOString());

    // Enhanced check to avoid clicking events
    if (e && e.target) {
      const eventElement = e.target.closest('.rbc-event');
      const hasEventClass = e.target.classList.contains('rbc-event') ||
                           e.target.classList.contains('rbc-event-content');

      if (eventElement || hasEventClass) {
        console.log('⚠️ Click detected on event, skipping slot selection');
        e.stopPropagation();
        return;
      }
    }

    // Prevent handling during loading
    if (isLoading) {
      console.log('⚠️ Calendar is loading, skipping slot selection');
      return;
    }

    // Use react-big-calendar's provided date/time directly
    const selectedDate = moment(slotInfo.start).format('YYYY-MM-DD');
    const selectedDateForInput = moment(slotInfo.start).format('YYYY-MM-DD');
    const selectedDateForDisplay = moment(slotInfo.start).format('MM/DD/YYYY');
    const selectedTime = moment(slotInfo.start).format('HH:mm');

    console.log('📅 Parsed from RBC:', {
      selectedDate,
      selectedTime,
      originalStart: slotInfo.start.toISOString()
    });

    // Dynamically modify URL parameters of reservation link in modal
    $('#schedule-modal .btn-yellow').each(function() {
      const $link = $(this);
      let href = $link.attr('href');

      if (href && href !== '#') {
        // Remove old start_time_date_part and start_time_time_part parameters
        href = href.replace(/[?&]start_time_date_part=[^&]*/g, '');
        href = href.replace(/[?&]start_time_time_part=[^&]*/g, '');

        // Add new parameters
        const separator = href.includes('?') ? '&' : '?';
        const newHref = `${href}${separator}start_time_date_part=${selectedDate}&start_time_time_part=${selectedTime}`;

        $link.attr('href', newHref);
      }
    });

    // When user clicks "Add leave schedule", update off-date-modal values
    $('#off-date-modal').off('shown.bs.modal.updateOffDateModal').on('shown.bs.modal.updateOffDateModal', function() {
      console.log('🔔 Manual off-date-modal trigger, updating with RBC slot data');
      updateOffDateModalValues(selectedDateForInput, selectedTime, timezone);
    });

    // Store selected date and time for later use
    window.selectedCalendarDateTime = {
      date: selectedDateForInput,
      dateDisplay: selectedDateForDisplay,
      time: selectedTime,
      timezone: timezone
    };

    console.log('💾 Stored calendar date/time from RBC:', window.selectedCalendarDateTime);

    // Open schedule modal when clicking empty area
    $('#schedule-modal').modal('show');
  };

  return (
    <div className="big-calendar" style={{ position: 'relative', height: '100%' }}>
      {isLoading && (
        <div className="loading-overlay" style={{
          position: 'absolute',
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          backgroundColor: 'rgba(255,255,255,0.8)',
          display: 'flex',
          justifyContent: 'center',
          alignItems: 'center',
          zIndex: 1000,
          pointerEvents: 'none'
        }}>
          <div style={{ pointerEvents: 'auto' }}>
          <i className="fa fa-spinner fa-spin fa-2x"></i>
          </div>
        </div>
      )}
      <Calendar
        defaultDate={props.month_date}
        key={calendarKey}
        localizer={localizer}
        events={convertedSchedules}
        startAccessor="start"
        endAccessor="end"
        views={['month', 'week', 'day', 'agenda']}
        onSelectEvent={handleSelectEvent}
        eventPropGetter={eventStyleGetter}
        onSelectSlot={handleSelectSlot}
        onNavigate={handleNavigate}
        selectable={true}
        longPressThreshold={250}
        scrollToTime={moment().hour(9).minute(0).second(0).toDate()}
        step={30}
        timeslots={2}
        popup
        popupOffset={30}
        messages={getCalendarMessages()}
        style={{ height: '100%', minHeight: '500px' }}
      />
    </div>
  );
};

export default SchedulesCalendar;