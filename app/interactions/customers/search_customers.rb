class Customers::SearchCustomers < ActiveInteraction::Base
  string :keyword

  def execute
    Customer.where("jp_last_name like :keyword or
                    jp_first_name like :keyword or
                    last_name like :keyword or
                    first_name like :keyword or
                    phone_number like :keyword", keyword: "%#{keyword}%")
  end
end
