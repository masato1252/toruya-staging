# frozen_string_literal: true

module ProductRequirements
  class Create < ActiveInteraction::Base
    object :requirer, class: ApplicationRecord
    object :requirement, class: ApplicationRecord
    integer :sale_page_id, default: nil

    def execute
      ProductRequirement.create(
        requirer: requirer,
        requirement: requirement,
        sale_page_id: sale_page_id
      )
    end
  end
end
