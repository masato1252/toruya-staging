# frozen_string_literal: true

module LineNoticeRequests
  class Create < ActiveInteraction::Base
    object :reservation
    object :customer

    def execute
      # バリデーション: 予約が顧客のものか確認
      unless reservation.customers.include?(customer)
        errors.add(:customer, :not_associated_with_reservation)
        return
      end

      # バリデーション: 店舗が無料プランか確認
      unless reservation.user.subscription.current_plan.free_level?
        errors.add(:reservation, :store_not_on_free_plan)
        return
      end

      # バリデーション: 既にpendingまたはapprovedのリクエストが存在しないか確認
      if LineNoticeRequest.where(status: [:pending, :approved]).exists?(reservation_id: reservation.id)
        errors.add(:reservation, :already_has_pending_request)
        return
      end

      # リクエスト作成
      line_notice_request = LineNoticeRequest.create!(
        reservation: reservation,
        user: reservation.user,
        status: :pending
      )

      # 店舗オーナーへLINE通知
      Notifiers::Users::LineNoticeRequestReceived.run(
        receiver: reservation.user,
        line_notice_request: line_notice_request
      )

      line_notice_request
    end
  end
end

