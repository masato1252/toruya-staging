# From google to Toruya
# Import from original importing group and backup group
# If customer already had backup_google_group_id, don't need to backup in another group
class Customers::Import < ActiveInteraction::Base
  attr_reader :user
  object :contact_group, class: ContactGroup

  def execute
    @user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)

    import_google_contacts = if contact_group.google_group_id
                               # XXX: Some groups don't connect with user original google groups.
                               google_user.group_contacts(contact_group.google_group_id)
                             elsif contact_group.bind_all
                               google_user.contacts
                             end

    backup_google_contacts = google_user.group_contacts(contact_group.backup_google_group_id)
    all_backup_google_group_ids = user.contact_groups.pluck(:backup_google_group_id)

    backup_google_contacts.each do |google_contact|
      customer = build_customer(google_contact)
      customer.contact_group = contact_group
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
    commands = customers_without_backup_group.map do |customer|
      Expeditor::Command.new do
        google_user.update_contact(customer.google_contact_id, { add_group_ids: [contact_group.backup_google_group_id] })
      end.tap { |command| command.start_with_retry(tries: 3, sleep: 1) }
    end
    commands.each(&:get)
  end

  private

  def build_customer(google_contact)
    customer = user.customers.find_or_initialize_by(google_contact_id: google_contact.id)
    customer.build_by_google_contact(google_contact)
    customer
  end
end
