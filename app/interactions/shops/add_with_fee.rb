# frozen_string_literal: true

module Shops
  class AddWithFee < ActiveInteraction::Base
    object :user
    object :acting_staff, class: Staff, default: nil
    string :authorize_token, default: nil
    string :payment_intent_id, default: nil

    validate :validate_can_add_shop
    validate :validate_source_shop

    def execute
      charge = nil

      if shop_fee_required?
        charge_outcome = Subscriptions::ShopFeeCharge.run(
          user: user,
          authorize_token: authorize_token,
          payment_intent_id: payment_intent_id
        )

        unless charge_outcome.valid? && charge_outcome.result.completed?
          errors.merge!(charge_outcome.errors)
          return charge_outcome.result
        end

        charge = charge_outcome.result
      end

      shop = nil
      Shop.transaction do
        shop = create_shop_from_source!
        copy_business_schedules!(shop)
        assign_acting_staff_to_shop!(shop)
      end

      if charge && shop
        charge.details = charge.details.merge("shop_ids" => shop.id)
        charge.save!
      end

      shop
    end

    private

    def validate_can_add_shop
      return if user.subscription&.in_paid_plan? || user.permission_level == Plan::ENTERPRISE_LEVEL

      errors.add(:user, :not_paid_plan)
    end

    def validate_source_shop
      errors.add(:user, :no_shops) unless source_shop
    end

    def source_shop
      @source_shop ||= user.shops.order(:id).first
    end

    def shop_fee_required?
      user.permission_level != Plan::ENTERPRISE_LEVEL &&
        user.shops.count >= Plans::Fee::SHOP_NUMBER_CHARGE_THRESHOLD &&
        Plans::Fee.chargeable_for?(user, user.subscription.plan)
    end

    def create_shop_from_source!
      default_name = source_shop.read_attribute(:name)
      default_short_name = source_shop.read_attribute(:short_name).presence || default_name

      user.shops.create!(
        name: "#{default_name} (NEW)",
        short_name: "#{default_short_name} (NEW)",
        zip_code: source_shop.zip_code,
        address: source_shop.address,
        address_details: source_shop.address_details,
        phone_number: source_shop.phone_number,
        email: source_shop.email,
        website: source_shop.website,
        holiday_working: source_shop.holiday_working,
        holiday_working_option: source_shop.holiday_working_option,
        info_setup_completed: false
      )
    end

    def copy_business_schedules!(shop)
      source_shop.business_schedules.for_shop.find_each do |schedule|
        BusinessSchedules::Create.run!(
          shop: shop,
          attrs: {
            day_of_week: schedule.day_of_week,
            business_state: schedule.business_state,
            start_time: schedule.start_time&.strftime("%H:%M"),
            end_time: schedule.end_time&.strftime("%H:%M")
          }
        )
      end
    end

    def assign_acting_staff_to_shop!(shop)
      staff = acting_staff || user.staffs.first || compose(Staffs::CreateOwner, user: user).staff
      staff.shop_ids = (staff.shop_ids + [shop.id]).uniq
    end
  end
end
