class Customers::SearchCustomers < ActiveInteraction::Base
  string :keyword
  integer :last_customer_id, default: nil
  integer :pre_page, default: 50

  def execute
    scoped = Customer.order("id").limit(pre_page)
    scoped = scoped.where("id > ?", last_customer_id) if last_customer_id

    scoped.where("
      jp_last_name like :keyword or
      jp_first_name like :keyword or
      last_name like :keyword or
      first_name like :keyword or
      phone_number like :keyword", keyword: "%#{keyword}%")
  end
end
