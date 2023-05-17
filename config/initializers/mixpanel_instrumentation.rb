Rails.application.config.to_prepare do
  if Rails.env.development? # unsubscribe to reload instrument class changes
    ActiveSupport::Notifications.unsubscribe 'process_action.action_controller'
  end

  ActiveSupport::Notifications.subscribe 'process_action.action_controller', ProcessActionInstrument.new
end
