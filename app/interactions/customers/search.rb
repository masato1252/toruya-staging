# frozen_string_literal: true

class Customers::Search < ActiveInteraction::Base
  PER_PAGE = 20

  object :super_user, class: User
  object :current_user_staff, class: Staff
  string :keyword
  integer :page, default: 1
  integer :pre_page, default: PER_PAGE

  def execute
    scoped =
      super_user
      .customers
      .contact_groups_scope(current_user_staff)
      .jp_chars_order
      .includes(:social_customer, :rank, :contact_group, updated_by_user: :profile)
      .page(page)
      .per(pre_page)

    scoped.where("
      phonetic_last_name ilike :keyword or
      phonetic_first_name ilike :keyword or
      last_name ilike :keyword or
      first_name ilike :keyword", keyword: "%#{keyword}%")
  end
end
