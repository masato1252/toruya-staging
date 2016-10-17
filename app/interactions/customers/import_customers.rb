# From google to Toruya
class Customers::ImportCustomers < ActiveInteraction::Base
  object :user, class: User
  string :google_group_id

  def execute
    google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
    google_contacts = google_user.group_contacts(google_group_id)

    google_contacts.each do |google_contact|
      customer = user.customers.find_or_initialize_by(google_contact_id: google_contact.id)
      customer.first_name = google_contact.first_name
      customer.last_name = google_contact.last_name
      customer.phonetic_last_name = google_contact.phonetic_last_name
      customer.phonetic_first_name = google_contact.phonetic_first_name
      customer.google_contact_group_ids = google_contact.group_ids
      customer.birthday = Date.parse(google_contact.birthday) if google_contact.birthday
      customer.address = primary_part_address(google_contact.addresses)
      customer.google_account_token = user.access_token
      customer.save
    end
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
    if address.city || address.region
      "#{address.city},#{address.region}"
    end
  end
end
