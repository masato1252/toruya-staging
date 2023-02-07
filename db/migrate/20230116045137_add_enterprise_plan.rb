class AddEnterprisePlan < ActiveRecord::Migration[6.0]
  def up
    Plan.create(position: 6, level: :enterprise)
  end

  def down
    Plan.where(level: :enterprise).destroy_all
  end
end
