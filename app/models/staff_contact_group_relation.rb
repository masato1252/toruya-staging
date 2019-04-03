# == Schema Information
#
# Table name: staff_contact_group_relations
#
#  id                            :integer          not null, primary key
#  staff_id                      :integer          not null
#  contact_group_id              :integer          not null
#  contact_group_read_permission :integer          default("reservations_only_readable"), not null
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
    reservations_only_readable: 0,
    details_readable: 1
  }

  belongs_to :staff
  belongs_to :contact_group
end
