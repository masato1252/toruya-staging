class AddIntroductionToStaffs < ActiveRecord::Migration[5.2]
  def change
    add_column :staffs, :introduction, :text, default: nil
  end
end
