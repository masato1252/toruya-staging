class Groups::Delete < ActiveInteraction::Base
  object :contact_group, class: ContactGroup

  def execute
    unless contact_group.backup_google_group_id
      contact_group.destroy
      return
    end

    user = contact_group.user
    google_user = user.google_user

    # delete toruya backup google group and binding original google group
    if google_user.delete_group(contact_group.backup_google_group_id) && google_user.delete_group(contact_group.google_group_id)
      contact_group.with_lock do
        contact_group.customers.find_each do |customer|
          google_group_ids = customer.google_contact_group_ids
          google_group_ids.delete(contact_group.backup_google_group_id)
          google_group_ids.delete(contact_group.google_group_id)

          customer.update(
            contact_group_id: nil,
            google_contact_group_ids: google_group_ids
          )
        end

        contact_group.google_group_id = nil
        contact_group.destroy
      end
    end
  end
end
