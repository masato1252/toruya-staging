class Customers::Search < ActiveInteraction::Base
  PER_PAGE = 50

  object :super_user, class: User
  string :keyword
  integer :page, default: 1
  integer :pre_page, default: PER_PAGE

  def execute
    scoped = super_user.customers.jp_chars_order.includes(:rank, :contact_group, :updated_by_user).page(page).per(pre_page)

    scoped.where("
      phonetic_last_name ilike :keyword or
      phonetic_first_name ilike :keyword or
      last_name ilike :keyword or
      first_name ilike :keyword", keyword: "%#{keyword}%")
  end
end
