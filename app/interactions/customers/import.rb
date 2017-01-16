# From google to Toruya
# Import from original importing group and backup group
# If customer already had backup_google_group_id, don't need to backup in another group
class Customers::Import < ActiveInteraction::Base
  attr_reader :user
  object :contact_group, class: ContactGroup

  def execute
    @user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    # XXX: Some groups don't connect with user original google groups.
    import_google_contacts = google_user.group_contacts(contact_group.google_group_id) if contact_group.google_group_id
    backup_google_contacts = google_user.group_contacts(contact_group.backup_google_group_id)
    all_backup_google_group_ids = user.contact_groups.pluck(:backup_google_group_id)

    backup_google_contacts.each do |google_contact|
      customer = build_customer(google_contact)
      customer.save
    end

    customers_without_backup_group = []

    (import_google_contacts || []).each do |google_contact|
      customer = build_customer(google_contact)

      if (customer.google_contact_group_ids & all_backup_google_group_ids).blank?
        customers_without_backup_group << customer
        customer.google_contact_group_ids << contact_group.backup_google_group_id
        customer.contact_group = contact_group
      end

      customer.save
    end

    # Add user to Toruya backup group
    customers_without_backup_group.each do |customer|
      google_user.update_contact(customer.google_contact_id, { add_group_ids: [contact_group.backup_google_group_id] })
    end
    # https://rollbar.com/ilake/kasaike/items/201/
    # threads = customers_without_backup_group.map do |customer|
    #   Thread.new do
    #     ActiveRecord::Base.connection_pool.with_connection do
    #       google_user.update_contact(customer.google_contact_id, { add_group_ids: [contact_group.backup_google_group_id] })
    #     end
    #   end
    # end
    # threads.each(&:join)
  end

  private

  def build_customer(google_contact)
    customer = user.customers.find_or_initialize_by(google_contact_id: google_contact.id)
    customer.build_by_google_contact(google_contact)
    customer
  end
end
