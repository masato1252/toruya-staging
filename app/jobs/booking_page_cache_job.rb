# frozen_string_literal: true

class BookingPageCacheJob < ApplicationJob
  queue_as :low_priority

  # Add timeout and retry settings
  retry_on StandardError, wait: :polynomially_longer, attempts: 3
  discard_on ActiveJob::DeserializationError

  # Job timeout after 2 hours (for very large booking pages)
  around_perform do |job, block|
    Timeout.timeout(2.hours) do
      block.call
    end
  rescue Timeout::Error
    Rails.logger.error "BookingPageCacheJob timed out for booking_page_id: #{job.arguments.first.id}"
    raise
  end

  def perform(booking_page)
    start_time = Time.current
    Rails.logger.info "🚀 Starting BookingPageCacheJob for booking_page_id: #{booking_page.id}"

    # Validate booking page
    unless booking_page.persisted?
      Rails.logger.error "❌ BookingPage not found or not persisted: #{booking_page.id}"
      return
    end

    # Check if booking page has any booking options
    booking_option_count = booking_page.booking_option_ids.size
    if booking_option_count == 0
      Rails.logger.info "⚠️  No booking options found for booking_page_id: #{booking_page.id}"
      return
    end

    # Calculate date range (2 months from today)
    date_range = Date.current..(Date.current + 2.months)
    total_dates = date_range.count

    Rails.logger.info "📊 Cache job stats:"
    Rails.logger.info "  - Date range: #{date_range.first} to #{date_range.last} (#{total_dates} days)"
    Rails.logger.info "  - Booking options: #{booking_option_count}"
    Rails.logger.info "  - Estimated operations: #{total_dates * booking_option_count}"

    # Process in batches to avoid memory issues
    batch_size = calculate_optimal_batch_size(booking_option_count)
    processed_count = 0
    error_count = 0

    date_range.each_slice(batch_size) do |date_batch|
      batch_start_time = Time.current

      begin
        date_batch.each do |date|
          # Skip if date is outside booking page's available range
          next if date < booking_page.available_booking_start_date
          next if date > booking_page.available_booking_end_date

          process_single_date(booking_page, date)
          processed_count += 1

          # Log progress every 10 dates
          if processed_count % 10 == 0
            elapsed_time = Time.current - start_time
            avg_time_per_date = elapsed_time / processed_count
            estimated_remaining = (total_dates - processed_count) * avg_time_per_date

            Rails.logger.info "📈 Progress: #{processed_count}/#{total_dates} dates (#{(processed_count.to_f/total_dates*100).round(1)}%) " \
                             "- Elapsed: #{elapsed_time.round(1)}s, ETA: #{estimated_remaining.round(1)}s"
          end
        end

        batch_elapsed = Time.current - batch_start_time
        Rails.logger.debug "✅ Batch completed: #{date_batch.size} dates in #{batch_elapsed.round(2)}s"

        # Small delay between batches to prevent overwhelming the database
        sleep(0.1) if date_batch.size > 5

      rescue => e
        error_count += 1
        Rails.logger.error "❌ Error processing batch starting #{date_batch.first}: #{e.message}"
        Rails.logger.error e.backtrace.first(3).join("\n")

        # If too many errors, stop the job
        if error_count > 5
          Rails.logger.error "💥 Too many errors (#{error_count}), stopping job"
          raise "Too many errors in BookingPageCacheJob"
        end
      end
    end

    total_elapsed = Time.current - start_time
    Rails.logger.info "🎉 BookingPageCacheJob completed!"
    Rails.logger.info "📊 Final stats:"
    Rails.logger.info "  - Total time: #{total_elapsed.round(2)}s (#{(total_elapsed/60).round(2)} minutes)"
    Rails.logger.info "  - Processed dates: #{processed_count}/#{total_dates}"
    Rails.logger.info "  - Errors: #{error_count}"
    Rails.logger.info "  - Average time per date: #{(total_elapsed/processed_count).round(3)}s" if processed_count > 0

  rescue => e
    Rails.logger.error "💥 BookingPageCacheJob failed for booking_page_id: #{booking_page.id}"
    Rails.logger.error "Error: #{e.message}"
    Rails.logger.error e.backtrace.first(5).join("\n")
    raise
  end

  private

  # Calculate optimal batch size based on booking options count
  def calculate_optimal_batch_size(booking_option_count)
    case booking_option_count
    when 0..2
      20  # Small booking pages can handle larger batches
    when 3..5
      10  # Medium booking pages
    when 6..10
      5   # Large booking pages
    else
      3   # Very large booking pages - process carefully
    end
  end

  # Process cache for a single date with error handling
  def process_single_date(booking_page, date)
    date_start_time = Time.current

    begin
      # Use a shorter timeout for individual dates
      Timeout.timeout(5.minutes) do
      ::Booking::Cache.run(booking_page: booking_page, date: date)
      end

      date_elapsed = Time.current - date_start_time

      # Log slow dates for investigation
      if date_elapsed > 30.seconds
        Rails.logger.warn "⚠️  Slow date processing: #{date} took #{date_elapsed.round(2)}s"
      end

    rescue Timeout::Error
      Rails.logger.error "⏰ Timeout processing date #{date} for booking_page_id: #{booking_page.id}"
      raise
    rescue => e
      Rails.logger.error "❌ Error processing date #{date}: #{e.message}"
      raise
    end
  end
end
