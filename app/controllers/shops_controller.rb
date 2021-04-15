# frozen_string_literal: true

class ShopsController < ActionController::Base
  skip_before_action :track_ahoy_visit
  layout "booking"

  def show
    @shop = Shop.find(params[:id])
  end
end
