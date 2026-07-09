# frozen_string_literal: true

# Wraps v1 receipt_context JSON for settings/payments/receipt.pdf.erb
class CompatReceiptPresenter
  MoneyLike = Struct.new(:format, keyword_init: true)

  def initialize(payload)
    @payload = payload
  end

  def completed?
    @payload["completed"]
  end

  def refunded?
    @payload["refunded"]
  end

  def is_a?(klass)
    klass.name == "LineNoticeCharge" && line_notice_charge?
  end

  def line_notice_charge?
    @payload["charge_type"] == "line_notice_charge"
  end

  def amount
    MoneyLike.new(format: @payload["amount_formatted"])
  end

  def amount_money
    amount
  end

  def charge_date
    Date.parse(@payload["charge_date"])
  end

  def created_at
    Time.zone.parse(@payload["created_at"])
  end

  def order_id
    @payload["order_id"]
  end

  def details
    @payload["details"] || {}
  end

  def expired_date
    value = @payload["expired_date"]
    value.present? ? Date.parse(value) : nil
  end

  def shop_fee?
    @payload["shop_fee"]
  end

  def with_shop_fee?
    @payload["with_shop_fee"]
  end

  def user
    OpenStruct.new(shops: OpenStruct.new(count: @payload["shop_count"].to_i))
  end

  def reservation
    line_notice = @payload["line_notice"]
    return nil unless line_notice

    OpenStruct.new(
      start_time: Time.zone.parse(line_notice["reservation_start_time"]),
      customers: [
        OpenStruct.new(
          last_name: line_notice["customer_last_name"],
          first_name: line_notice["customer_first_name"]
        )
      ]
    )
  end
end
