# frozen_string_literal: true

module ControllerHelpers
  extend ActiveSupport::Concern

  private

  def json_response(outcome, data = {})
    {
      status: outcome.valid? ? "successful" : "failed",
      error_message: outcome.errors.full_messages.join(", "),
    }.merge!(data || {})
  end

  def return_json_response(outcome, data = {})
    if outcome.invalid?
      Rollbar.error("#{outcome.class} service failed", {
        errors: outcome.errors.details
      })
    end
    render json: json_response(outcome, data), status: outcome.valid? ? :ok : :bad_request
  end

  # Helper method to find error with specific key from any category in outcome.errors.details
  def find_error_with_key(outcome, key)
    return nil unless outcome.invalid?

    outcome.errors.details.values.flatten.find { |error| error[key].present? }
  end

  # Helper method to find error with client_secret from any key in outcome.errors.details
  def find_error_with_client_secret(outcome)
    result = find_error_with_key(outcome, :client_secret)
    # client_secretが実際に存在する場合のみ返す（空ハッシュはfalsyとして扱う）
    result.present? && result[:client_secret].present? ? result : nil
  end

  # Helper method to check if outcome has 3DS authentication requirements
  def requires_3ds_action?(outcome)
    find_error_with_client_secret(outcome).present?
  end

  def set_up_previous_cookie(cookie_name, value)
    cookies.clear_across_domains("current_scope_#{cookie_name}")
    cookies.set_across_domains("current_scope_#{cookie_name}", value, expires: 20.years.from_now)
  end

  def clean_previous_cookie(cookie_name)
    cookies.clear_across_domains("current_scope_#{cookie_name}")
  end

  # 公開イベントページへの ?rs (出展店舗紹介) / ?ru (ユーザシェア) 由来の
  # 流入リファラーを encrypted cookie (event_ref_<slug>) に蓄積する。
  # 参加登録時にこの cookie を読み出して event_participants に永続化する。
  # last-touch 方式: 同じ event 内で何度踏んでも最後の値が採用される。
  def capture_event_referrers
    return if @event.blank?

    cookie_key = "event_ref_#{@event.slug}"
    current = cookies.encrypted[cookie_key]
    current = current.is_a?(Hash) ? current.dup : {}

    rs_param = params[:rs].to_s.presence
    if rs_param && Shop.active.exists?(id: rs_param)
      current["rs"] = rs_param.to_i
    end

    ru_param = params[:ru].to_s.presence
    if ru_param && EventLineUser.exists?(id: ru_param)
      current["ru"] = ru_param.to_i
    end

    if current.any?
      cookies.encrypted[cookie_key] = {
        value: current,
        expires: 60.days.from_now,
        httponly: true
      }
    end
  end
end
