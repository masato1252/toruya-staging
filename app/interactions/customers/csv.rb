# frozen_string_literal: true

require 'csv_generator'

class Customers::Csv < ActiveInteraction::Base
  HEADERS = [
    'id',
    'last_name',
    'first_name',
    'phonetic_last_name',
    'phonetic_first_name',
    'display_address',
    'email',
    'phone_number',
    'custom_id',
    'birthday',
    'memo'
  ]
  object :user

  def execute
    CsvGenerator.perform do |csv|
      csv << HEADERS

      user.customers.find_each do |customer|
        csv << [
          customer.id,
          customer.last_name,
          customer.first_name,
          customer.phonetic_last_name,
          customer.phonetic_first_name,
          customer.display_address,
          customer.email,
          customer.phone_number,
          customer.custom_id,
          customer.birthday,
          customer.memo
        ]
      end
    end
  end
end
