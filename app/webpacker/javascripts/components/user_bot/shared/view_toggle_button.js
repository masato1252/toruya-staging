import React from 'react';
import I18n from 'i18n-js/index.js.erb';
import Routes from 'js-routes.js';

const ViewToggleButton = ({ props }) => {
  const { current_mode, business_owner_id } = props;
  const toggleMode = async () => {
    try {
      // 構建正確的 URL
      const url = Routes.toggle_mode_lines_user_bot_schedules_path(business_owner_id);

      // 使用 fetch 發送 POST 請求切換模式
      const response = await fetch(url, {
        method: 'POST',
        headers: {
          'X-Requested-With': 'XMLHttpRequest',
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content')
        }
      });

      if (response.ok) {
        // 重新載入頁面以顯示新的視圖
        window.location.reload();
      } else {
        console.error('Failed to toggle mode:', response.status);
      }
    } catch (error) {
      console.error('Error toggling mode:', error);
    }
  };

  const nextMode = current_mode === 'calendar' ? 'list' : 'calendar';
  const buttonText = nextMode === 'calendar' ?
    I18n.t('user_bot.dashboards.schedules.calendar_view') :
    I18n.t('user_bot.dashboards.schedules.list_view');

  const iconClass = nextMode === 'calendar' ? 'fa-calendar' : 'fa-list';

  return (
    <button
      onClick={toggleMode}
      className="view-toggle-btn"
      title={buttonText}
    >
      <i className={`fa ${iconClass}`} aria-hidden="true"></i>
    </button>
  );
};

export default ViewToggleButton;