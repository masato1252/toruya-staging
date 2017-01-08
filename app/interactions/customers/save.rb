class Customers::Save < ActiveInteraction::Base
  DELIMITER = "-=-".freeze

  set_callback :type_check, :before do
    # if params[:primary_address] && (params[:primary_address][:region].present? || params[:primary_address][:city].present?)
    params[:address] = [params[:primary_address][:region], params[:primary_address][:city]].reject(&:blank?).join(" ")
    params[:primary_address] = {
        type: params[:primary_address][:type],
        value: {
          postcode: "#{params[:primary_address][:postcode1]}#{params[:primary_address][:postcode2]}",
          region: params[:primary_address][:region],
          city: params[:primary_address][:city],
          street: [params[:primary_address][:street1], params[:primary_address][:street2]].reject(&:blank?).join(",")
        },
        primary: true
    }
    params[:other_addresses] = params[:other_addresses].present? ? JSON.parse(params[:other_addresses]) : []
    params[:addresses] = [params[:primary_address]] + params[:other_addresses]
    # end

    if params[:dob]
      params[:birthday] = Date.new(params[:dob][:year].try(:to_i) || Date.today.year,
                                   params[:dob][:month].try(:to_i) || 1,
                                   params[:dob][:day].try(:to_i) || 1)
    end

    if params[:phone_numbers].present?
      type, *number = params[:primary_phone].split(DELIMITER)
      params[:primary_phone] = { "type" => type, "value" => number.join(DELIMITER) }

      params[:phone_numbers].find do |phone_number_hash|
        if phone_number_hash == params[:primary_phone]
          phone_number_hash.merge!("primary" => true)
        end
      end
    end

    if params[:emails].present?
      type, *email= params[:primary_email].split(DELIMITER)
      params[:primary_email] = { "type" => type, "value" => { "address" => email.join(DELIMITER) } }

      params[:emails].find do |email_hash|
        if email_hash == params[:primary_email]
          email_hash.merge!("primary" => true)
        end
      end
    end
  end

  object :user
  hash :params do
    integer :id, default: nil, base: 10
    integer :contact_group_id, base: 10
    integer :rank_id, base: 10
    string :last_name, default: nil
    string :first_name, default: nil
    string :phonetic_last_name, default: nil
    string :phonetic_first_name, default: nil

    hash :primary_phone, default: nil
    hash :primary_email, default: nil
    hash :primary_address, default: nil do
      string :type, default: nil
      string :postcode1, default: nil
      string :postcode2, default: nil
      string :region, default: nil
      string :city, default: nil
      string :street1, default: nil
      string :street2, default: nil
    end
    array :addresses, default: []
    array :other_addresses, default: []
    string :address, default: nil

    array :phone_numbers, default: []
    array :emails, default: []
    hash :dob, default: nil do
      integer :year, default: nil
      integer :month, default: nil
      integer :day, default: nil
    end
    date :birthday, default: nil
    string :custom_id, default: nil
    string :memo, default: nil
  end

  def execute
    if params[:id].present?
      customer = user.customers.find(params[:id])
      customer.attributes = params.merge(updated_at: Time.zone.now)
    else
      customer = user.customers.new(params)
    end

    if customer.contact_group_id_changed?
      google_group_ids = customer.google_contact_group_ids
      new_google_group_id = user.contact_groups.find(customer.contact_group_id).backup_google_group_id
      google_groups_changes = { add_group_ids: new_google_group_id }
      google_group_ids.push(new_google_group_id)

      if customer.contact_group_id_was
        legacy_google_group_id = user.contact_groups.find(customer.contact_group_id_was).backup_google_group_id
        google_groups_changes.merge!(remove_group_ids: legacy_google_group_id)
        google_group_ids.delete(legacy_google_group_id)
      end

      customer.google_contact_group_ids = google_group_ids
    end

    # TODO: test two addresses case
    if customer.valid?
      google_user = GoogleContactsApi::User.new(user.access_token, user.refresh_token)
      google_contact_attributes = customer.google_contact_attributes(google_groups_changes)

      if customer.google_contact_id
        google_user.update_contact(customer.google_contact_id, google_contact_attributes)
      else
        result = google_user.create_contact(google_contact_attributes)
        customer.google_contact_id = result.id
        customer.google_uid = user.uid
      end

      customer.save
    end

    customer
  end
end
