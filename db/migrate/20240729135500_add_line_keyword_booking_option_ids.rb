class AddLineKeywordBookingOptionIds < ActiveRecord::Migration[7.0]
  def change
    User.find_each do |user|
      user.create_user_setting unless user.user_setting
      user.user_setting.update(
        line_keyword_booking_option_ids: user.booking_options.active.order(updated_at: :desc).pluck(:id)
      )
    end
  end
end
