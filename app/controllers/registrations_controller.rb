# frozen_string_literal: true

class RegistrationsController < Devise::RegistrationsController
  layout "application"  # レイアウト名を指定（home, application, simple など）

  # 必要に応じて特定のアクションだけレイアウトを変えることも可能
  def new
    render layout: "booking"
  end
end

