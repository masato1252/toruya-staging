class OmniauthSetup
  # OmniAuth expects the class passed to setup to respond to the #call method.
  # env - Rack environment
  def self.call(env)
    new(env).setup
  end

  # Assign variables and create a request object for use later.
  # env - Rack environment
  def initialize(env)
    @env = env
    @request = ActionDispatch::Request.new(env)
  end

  # The main purpose of this method is to set the consumer key and secret.
  def setup
    @env['omniauth.strategy'].options.merge!(custom_credentials)
  end

  # Use the subdomain in the request to find the account with credentials
  def custom_credentials
    account = SocialAccount.find(@request.cookies["oauth_social_account_id"])

    {
      client_id: account.login_channel_id,
      client_secret: account.raw_login_channel_secret
    }
  end
end
