# frozen_string_literal: true

class CustomerPaymentBonus
  include ActiveAttr::Model

  attribute :sale_page_id, type: Integer
  attribute :bonus_month, type: Integer
end
