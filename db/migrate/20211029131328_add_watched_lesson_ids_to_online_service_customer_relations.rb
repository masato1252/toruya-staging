class AddWatchedLessonIdsToOnlineServiceCustomerRelations < ActiveRecord::Migration[6.0]
  def change
    # https://stackoverflow.com/a/34078666/609365
    # enable_extension "btree_gin"
    # https://www.postgresql.org/docs/9.1/arrays.html
    add_column :online_service_customer_relations, :watched_lesson_ids, :string, array: true, default: []
  end
end
