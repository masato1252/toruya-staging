class CreateUserSettings < ActiveRecord::Migration[7.0]
  def change
    create_table :user_settings do |t|
      t.references :user, index: true
      t.json :content, default: {}
    end

    User.find_each do |user|
      user.create_user_setting unless user.user_setting
      user.user_setting.update(
        line_keyword_booking_page_ids: user.booking_pages.where(draft: false, line_sharing: true).started.order("booking_pages.updated_at DESC").pluck(:id)
      )
    end
  end
end
