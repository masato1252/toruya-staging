class AddTagsToEpisodes < ActiveRecord::Migration[6.0]
  def change
    add_column :episodes, :tags, :string, array: true
    change_column_default :episodes, :tags, []

    add_column :online_services, :tags, :string, array: true
    change_column_default :online_services, :tags, []
  end
end
