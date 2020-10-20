class Customers::Save < ActiveInteraction::Base
  DELIMITER = "-=-".freeze

  # {"id"=>"637",
  #  "contact_group_id"=>"18",
  #  "rank_id"=>"2",
  #  "phonetic_last_name"=>"886910819086",
  #  "phonetic_first_name"=>"vvv",
  #  "last_name"=>"zhang",
  #  "first_name"=>"guorong",
  #  "primary_phone"=>"home-=-886910819086",
  #  "primary_email"=>"home-=-lake.ilakela@gmail.com",
  #  "primary_address"=>{
  #    "type"=>"home",
  #    "postcode1"=>"111",
  #    "postcode2"=>"111",
  #    "region"=>"北海道",
  #    "city"=>"",
  #    "street1"=>"4F.-3",
  #    "street2"=>" No.125, Sinsing St, No.125, Sinsing St, fffTainan 7107108" 
  #  },
  #  "phone_numbers"=>[
  #    {"type"=>"mobile",
  #     "value"=>"q weq we qaa"},
  #     {"type"=>"home",
  #      "value"=>"886910819086"},
  #      {"type"=>"home",
  #       "value"=>"1234566"}
  #  ],
  #  "emails"=>[
  #    {"type"=>"home",
  #     "value"=>{"address"=>"lake.ilakela@gmail.com"}},
  #  {"type"=>"mobile",
  #   "value"=>{"address"=>"qweqqqqqq"}},
  #  {"type"=>"work",
  #   "value"=>{"address"=>"qweqwewqewqeeqw"}}
  #  ],
  #  "custom_id"=>"",
  #  "dob"=>{"year"=>"1916",
  #          "month"=>"1",
  #          "day"=>"1"},
  #          "memo"=>""}

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

    if params[:dob] && params[:dob][:year].present? && params[:dob][:month].present? && params[:dob][:day].present?
      params[:birthday] = Date.new(params[:dob][:year].try(:to_i) || Date.current.year,
                                   params[:dob][:month].try(:to_i) || 1,
                                   params[:dob][:day].try(:to_i) || 1)
    else
      params[:birthday] = nil
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
  object :current_user, class: User
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
      string :year, default: nil
      string :month, default: nil
      string :day, default: nil
    end
    date :birthday, default: nil
    string :custom_id, default: nil
    string :memo, default: nil
  end

  def execute
    # XXX: How to assign emails, phone_numbers to customer
    # emails: [{ type: "mobile", value: { address: customer_email }, primary: true }],
    # phone_numbers: [{ type: "mobile", value: customer_phone_number, primary: true }]
    if params[:id].present?
      customer = user.customers.find(params[:id])
      customer.attributes = params.merge(updated_at: Time.zone.now, updated_by_user_id: current_user.id)
    else
      customer = user.customers.new(params.merge(updated_by_user_id: current_user.id))
    end

    # XXX Always update google_group_id
    google_group_ids = customer.google_contact_group_ids
    new_google_group_id = user.contact_groups.find(customer.contact_group_id).backup_google_group_id
    google_groups_changes = { add_group_ids: new_google_group_id }
    google_group_ids.push(new_google_group_id)

    if customer.contact_group_id_changed? && customer.contact_group_id_was
      legacy_google_group_id = user.contact_groups.find(customer.contact_group_id_was).backup_google_group_id
      google_groups_changes.merge!(remove_group_ids: legacy_google_group_id)
      google_group_ids.delete(legacy_google_group_id)
    end

    customer.google_contact_group_ids = google_group_ids.uniq

    if customer.valid?
      google_user = user.google_user
      google_contact_attributes = customer.google_contact_attributes(google_groups_changes)

      if customer.google_contact_id
        new_google_contact = google_user.update_contact(customer.google_contact_id, google_contact_attributes)

        if new_google_contact.try(:id)
          customer.google_contact_id = new_google_contact.id
        end
      else
        result = google_user.create_contact(google_contact_attributes)
        customer.google_contact_id = result.id
        customer.google_uid = user.uid
      end
      # XXX: Some user use 携帯 by themselves, not system default category.
      # https://gist.github.com/ilake/cf20b88acc2c3b28021f6c234704fa33 email types migration gist.
      # home,mobile,other,work
      customer_emails = customer.emails || []
      customer.email_types = customer_emails.map { |email| email[:type].to_s == "携帯" ? "mobile" : email[:type].to_s }.uniq.sort.join(",")
      customer.save
    end

    customer
  rescue => e
    Rollbar.error(e)
    errors.add(:base, :google_down)
  end
end
