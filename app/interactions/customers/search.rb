class Customers::Search < ActiveInteraction::Base
  PER_PAGE = 50

  object :super_user, class: User
  string :keyword
  integer :last_customer_id, default: nil
  integer :pre_page, default: PER_PAGE

  def execute
    scoped = super_user.customers.includes(:rank, :contact_group).order("id").limit(pre_page)
    scoped = scoped.where("id > ?", last_customer_id) if last_customer_id

    scoped.where("
      phonetic_last_name ilike :keyword or
      phonetic_first_name ilike :keyword or
      last_name ilike :keyword or
      first_name ilike :keyword", keyword: "%#{keyword}%")
  end
end
