class Customers::RequestUpdate < ActiveInteraction::Base
  object :reservation_customer

  def execute
    customer.attributes = new_customer_info.name_attributes
    assign_emails
    assign_phone_numbers
    assign_addresses

    if customer.valid?
      google_user = user.google_user
      google_contact_attributes = customer.google_contact_attributes
      google_user.update_contact(customer.google_contact_id, google_contact_attributes)

      # XXX:
      # Handle some dirty data, to convert 携帯 to mobile
      customer.email_types = Array.wrap(customer.emails).map { |email| email[:type].to_s == "携帯" ? "mobile" : email[:type].to_s }.uniq.sort.join(",")
      customer.save
    end
  end

  private

  def customer
    @customer ||= reservation_customer.customer.with_google_contact
  end

  def new_customer_info
    @new_customer_info ||= reservation_customer.customer_info
  end

  def user
    customer.user
  end

  def assign_emails
    # XXX:
    # The format read and write emails in customer is different
    #
    # [Read]
    # customer.emails
    #
    # [
    #   {
    #     "type" => :mobile,
    #     "value" => {
    #       "address" => "lake.ilakela@gmail.com",
    #       "primary" => true,
    #       "label" => "mobile"
    #     },
    #     "primary" => true
    #   }
    # ]
    #
    # [Write]
    # customer.emails = new_emails
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> {
    #       "address" => "lake.ilakela@gmail.com4"
    #     },
    #     "primary"=>true
    #   }
    # ]
    if new_customer_info.email
      emails = customer.emails.map do |email_hash|
        Hashie::Mash.new({
          type: email_hash.type,
          value: {
            address: email_hash.value.address
          },
          primary: email_hash.value.primary
        })
      end

      primary_email_index = emails.find_index { |email_hash| email_hash.primary }

      if primary_email_index
        primary_email = emails[primary_email_index]
        primary_email.value.address = new_customer_info.email
        emails[primary_email_index] = primary_email
      else
        emails.push({
          "type" => :mobile,
          "value" => {
            "address" => new_customer_info.email,
          },
          "primary" => true,
        })
      end

      customer.emails = emails
    end
  end

  def assign_phone_numbers
    # XXX:
    # The format read and write addresses in customer is different
    #
    # [Read]
    # customer.phone_numbers
    # [
    #   {
    #     "type" => :home,
    #     "value" => "12312312",
    #     "primary" => true
    #   }
    # ]
    #
    # [Write]
    # customer.phone_numbers = new_phone_numbers
    #
    # [
    #   {
    #     "type"=> "mobile",
    #     "value"=> "12312312",
    #     "primary" => true
    #   }
    # ]
    if new_customer_info.phone_number
      phone_numbers = customer.phone_numbers

      primary_phone_index = phone_numbers.find_index { |phone_hash| phone_hash.primary }

      if primary_phone_index
        primary_phone = phone_numbers[primary_phone_index]
        primary_phone.value = new_customer_info.phone_number
        phone_numbers[primary_phone_index] = primary_phone
      else
        phone_numbers.push({
          "type" => :mobile,
          "value" => new_customer_info.phone_number,
          "primary" => true
        })
      end

      customer.phone_numbers = phone_numbers
    end
  end

  def assign_addresses
    # XXX:
    # The format read and write addresses in customer is different
    #
    # [Read]
    # customer.addresses
    #
    # [
    #   {
    #     "primary" => true,
    #     "type" => :home,
    #     "value" => {
    #       "primary" => true,
    #       "formatted_address" => "4F.-3, No.125, Sinsing StTainan\n岩手県",
    #       "street" => "4F.-3, No.125, Sinsing StTainan",
    #       "region" => "岩手県"
    #     }
    #   }
    # ]
    #
    # [Write]
    # customer.addresses = new_addresses
    #
    # [
    #   {
    #     "primary" => true,
    #     "type" => "home",
    #     "value" => {
    #       "postcode" => "",
    #       "region" => "岩手県",
    #       "city" => "",
    #       "street" => "4F.-3, No.125, Sinsing StTainan"
    #     },
    #   }
    # ]
    if new_customer_info.sorted_address_details.present?
      addresses = customer.addresses

      primary_address_index = addresses.find_index { |address_hash| address_hash.primary }

      if primary_address_index
        primary_address = addresses[primary_address_index]
        primary_address.value = {
          postcode: new_customer_info.address_details.postcode.presence || primary_address.value.postcode,
          region: new_customer_info.address_details.region.presence || primary_address.value.region,
          city: new_customer_info.address_details.city.presence || primary_address.value.city,
          street: [new_customer_info.address_details.street1, new_customer_info.address_details.street2].reject(&:blank?).join(",").presence || primary_address.value.street
        }

        addresses[primary_address_index] = primary_address
        customer.address = [primary_address.value[:region], primary_address.value[:city]].reject(&:blank?).join(" ")
      else
        addresses.push({
          "type" => :home,
          "primary" => true,
          "value" => {
            postcode: new_customer_info.address_details.postcode,
            region: new_customer_info.address_details.region,
            city: new_customer_info.address_details.city,
            street: [new_customer_info.address_details.street1, new_customer_info.address_details.street2].reject(&:blank?).join(",")
          }
        })
      end

      customer.addresses = addresses
    end
  end
end
