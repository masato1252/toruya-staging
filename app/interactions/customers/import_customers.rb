# From google to Toruya
# Import from original importing group and backup group
# If customer already had backup_google_group_id, don't need to backup in another group
class Customers::ImportCustomers < ActiveInteraction::Base
  attr_reader :user
  object :contact_group, class: ContactGroup

  def execute
    @user = contact_group.user
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    import_google_contacts = google_user.group_contacts(contact_group.google_group_id)
    backup_google_contacts = google_user.group_contacts(contact_group.backup_google_group_id)
    all_backup_google_group_ids = user.contact_groups.pluck(:backup_google_group_id)

    backup_google_contacts.each do |google_contact|
      customer = build_customer(google_contact)
      customer.save
    end

    customers_without_backup_group = []

    import_google_contacts.each do |google_contact|
      customer = build_customer(google_contact)

      if (customer.google_contact_group_ids & all_backup_google_group_ids).blank?
        customers_without_backup_group << customer
        customer.google_contact_group_ids << contact_group.backup_google_group_id
        customer.contact_group = contact_group
      end

      customer.save
    end

    # Add user to Toruya backup group
    threads = customers_without_backup_group.map do |customer|
      Thread.new do
        ActiveRecord::Base.connection_pool.with_connection do
          google_user.update_contact(customer.google_contact_id, { add_group_ids: [contact_group.backup_google_group_id] })
        end
      end
    end
    threads.each(&:join)
  end

  private

  def primary_address(addresses)
    return unless addresses

    if primary_address = addresses.find { |address_type, address| address.primary }
      primary_address
    elsif home_address = addresses.find { |address_type, address| address_type == "home" }
      home_address
    elsif work_address = addresses.find { |address_type, address| address_type == "work" }
      work_address
    else
      addresses.first
    end
  end

  def primary_part_address(addresses)
    return unless addresses

    address_type, address = primary_address(addresses)
    if address && (address.city || address.region)
      "#{address.city},#{address.region}"
    end
  end

  def build_customer(google_contact)
    customer = user.customers.find_or_initialize_by(google_contact_id: google_contact.id)
    customer.first_name = google_contact.first_name
    customer.last_name = google_contact.last_name
    customer.phonetic_last_name = google_contact.phonetic_last_name
    customer.phonetic_first_name = google_contact.phonetic_first_name
    customer.google_contact_group_ids = google_contact.group_ids
    customer.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
    customer.address = primary_part_address(google_contact.addresses)
    customer.google_uid = user.uid
    customer
  end
end
