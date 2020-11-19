class Customers::Create < ActiveInteraction::Base
  object :user
  string :customer_last_name
  string :customer_first_name
  string :customer_phonetic_last_name
  string :customer_phonetic_first_name
  string :customer_phone_number
  string :customer_email

  def execute
    begin
      customer_info_hash = {
        last_name: customer_last_name,
        first_name: customer_first_name,
        phonetic_last_name: customer_phonetic_last_name,
        phonetic_first_name: customer_phonetic_first_name,
        email_types: "mobile",
        emails: [{ type: "mobile", value: { address: customer_email }, primary: true }],
        phone_numbers: [{ type: "mobile", value: customer_phone_number, primary: true }]
      }

      customer = user.customers.new(customer_info_hash)
      google_user = user.google_user

      if google_user
        result = google_user.create_contact(customer.google_contact_attributes)
        customer.google_contact_id = result.id
        customer.google_uid = user.uid
      end

      if user.contact_groups.count == 1
        customer.contact_group_id = user.contact_groups.first.id
      end

      customer.save
    rescue => e
      Rollbar.error(e)
      errors.add(:base, :google_down)
    end

    if customer.new_record?
      errors.merge!(customer.errors)
    end

    customer
  end
end
