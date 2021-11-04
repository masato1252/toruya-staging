class AddStartOnDaysToLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :lessons, :start_after_days, :integer
    add_column :lessons, :start_at, :datetime
  end
end
