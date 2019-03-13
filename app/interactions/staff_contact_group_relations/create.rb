module StaffContactGroupRelations
  class Create < ActiveInteraction::Base
    object :staff
    object :contact_group
    string :contact_group_read_permission

    def execute
      StaffContactGroupRelation.create(staff: staff, contact_group: contact_group, contact_group_read_permission: contact_group_read_permission)
    end
  end
end
