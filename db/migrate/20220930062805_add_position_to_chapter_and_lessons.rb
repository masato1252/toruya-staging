class AddPositionToChapterAndLessons < ActiveRecord::Migration[6.0]
  def change
    add_column :chapters, :position, :integer
    change_column_default :chapters, :position, 0
    add_column :lessons, :position, :integer
    change_column_default :lessons, :position, 0
  end
end
