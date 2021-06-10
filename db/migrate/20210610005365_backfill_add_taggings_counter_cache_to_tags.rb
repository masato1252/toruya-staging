class BackfillAddTaggingsCounterCacheToTags < ActiveRecord::Migration[5.2]
  disable_ddl_transaction!

  def up
    ActsAsTaggableOn::Tag.unscoped.in_batches do |relation|
      relation.update_all taggings_count: 0
      sleep(0.01)
    end
  end
end
