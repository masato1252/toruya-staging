# frozen_string_literal: true

# == Schema Information
#
# Table name: sale_templates
#
#  id         :bigint           not null, primary key
#  edit_body  :json
#  view_body  :json
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class SaleTemplate < ApplicationRecord
end
