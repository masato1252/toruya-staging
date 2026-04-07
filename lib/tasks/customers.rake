# frozen_string_literal: true

namespace :customers do
  desc "Normalize +81/81 phone numbers to national format (0xx) for ja-locale shops"
  task normalize_phone_numbers: :environment do
    dry_run = ENV["DRY_RUN"] != "false"

    puts dry_run ? "[DRY RUN] Scanning..." : "[LIVE] Normalizing..."

    ja_user_ids = User.joins(:social_user)
                       .where(social_users: { locale: [nil, "ja"] })
                       .pluck(:id)
    updated = 0
    skipped = 0
    errors = 0

    Customer.where(user_id: ja_user_ids)
            .where("phone_numbers_details IS NOT NULL")
            .find_each do |customer|
      mobile = customer.phone_numbers_details&.find { |h| h["type"] == "mobile" && h["value"].present? }
      next unless mobile

      raw_value = mobile["value"].to_s.strip
      next unless raw_value.match?(/\A\+?81\d/) && !raw_value.start_with?("0")

      parsed = Phonelib.parse(raw_value)
      parsed = Phonelib.parse(raw_value, "JP") unless parsed.valid?

      unless parsed.valid? && parsed.countries.include?("JP")
        skipped += 1
        next
      end

      national = parsed.national(false)

      if dry_run
        puts "  [DRY] customer_id=#{customer.id} user_id=#{customer.user_id} " \
             "#{raw_value} -> #{national} (customer_phone_number: #{customer.customer_phone_number})"
        updated += 1
      else
        existing = Customer.where(user_id: customer.user_id, customer_phone_number: national)
                           .where.not(id: customer.id).first
        if existing
          puts "  [SKIP] customer_id=#{customer.id} #{raw_value} -> #{national} conflicts with customer_id=#{existing.id}"
          skipped += 1
          next
        end

        mobile["value"] = national
        customer.update_columns(
          phone_numbers_details: customer.phone_numbers_details,
          customer_phone_number: national
        )
        puts "  [OK] customer_id=#{customer.id} #{raw_value} -> #{national}"
        updated += 1
      end
    rescue => e
      errors += 1
      puts "  [ERROR] customer_id=#{customer.id}: #{e.message}"
    end

    puts "Done. #{dry_run ? 'Would update' : 'Updated'}: #{updated}, Skipped: #{skipped}, Errors: #{errors}"
  end
end
