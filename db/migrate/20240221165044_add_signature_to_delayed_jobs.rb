class AddSignatureToDelayedJobs < ActiveRecord::Migration[7.0]
  def change
    add_column :delayed_jobs, :signature, :string, index: true, unique: true
    add_index :delayed_jobs, [:signature], unique: true
  end
end
