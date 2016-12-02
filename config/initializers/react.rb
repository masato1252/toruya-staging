Rails.application.configure do
  # config.react.server_renderer_pool_size ||= 1  # ExecJS doesn't allow more than one on MRI
  # config.react.server_renderer_timeout ||= 20 # seconds
  # config.react.server_renderer = React::ServerRendering::SprocketsRenderer
  # config.react.server_renderer_options = {
  #   files: ["react-server.js", "underscore.js", "ui.js", "prerendered_components.js"], # files to load for prerendering
  #   replay_console: true,                 # if true, console.* will be replayed client-side
  # }
  config.react.camelize_props = true
end

