# frozen_string_literal: true

module MixpanelHelper
  def tracking_from
    Current.mixpanel_extra_properties = { _from: params[:_from] || "directly" }
  end
end
