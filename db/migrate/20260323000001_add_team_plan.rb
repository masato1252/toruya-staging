# frozen_string_literal: true

class AddTeamPlan < ActiveRecord::Migration[7.0]
  def up
    Plan.create!(position: 7, level: :team)
  end

  def down
    Plan.where(level: :team).destroy_all
  end
end
