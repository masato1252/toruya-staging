class SubdomainConstraint
  def self.[](subdomain)
    new(subdomain)
  end

  def initialize(subdomain)
    @subdomain = subdomain.to_s
  end

  def matches?(request)
    if Rails.configuration.x.env.production?
      request.subdomain == @subdomain
    else
      true
    end
  end
end

