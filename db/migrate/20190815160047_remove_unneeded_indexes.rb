class RemoveUnneededIndexes < ActiveRecord::Migration[5.2]
  def change
    remove_index :contact_groups, name: "index_contact_groups_on_user_id"
    remove_index :filtered_outcomes, name: "index_filtered_outcomes_on_user_id"
    remove_index :menus, name: "index_menus_on_user_id"
    remove_index :shop_menu_repeating_dates, name: "index_shop_menu_repeating_dates_on_shop_id"
    remove_index :shops, name: "index_shops_on_user_id"
    remove_index :staff_accounts, name: "index_staff_accounts_on_owner_id"
    remove_index :staff_accounts, name: "staff_account_index"
    remove_index :staff_contact_group_relations, name: "index_staff_contact_group_relations_on_staff_id"
    remove_index :staffs, name: "index_staffs_on_user_id"
    remove_index :subscription_charges, name: "index_subscription_charges_on_user_id"
  end
end
