class CreateUserMetrics < ActiveRecord::Migration[7.0]
  def change
    create_table :user_metrics do |t|
      t.references :user, index: true
      t.json :content, default: {}
    end

    User.find_each do |user|
      user.create_user_metric
    end
  end
end
