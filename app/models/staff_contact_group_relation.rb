# == Schema Information
#
# Table name: staff_contact_group_relations
#
#  id                            :integer          not null, primary key
#  staff_id                      :integer          not null
#  contact_group_id              :integer          not null
#  contact_group_read_permission :integer          default("reservation_only"), not null
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#
# Indexes
#
#  index_staff_contact_group_relations_on_contact_group_id  (contact_group_id)
#  index_staff_contact_group_relations_on_staff_id          (staff_id)
#  staff_contact_group_unique_index                         (staff_id,contact_group_id) UNIQUE
#

class StaffContactGroupRelation < ApplicationRecord
  enum contact_group_read_permission: {
    reservation_only: 0,
    detail: 1
  }

  belongs_to :staff
  belongs_to :contact_group
end
