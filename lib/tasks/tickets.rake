# frozen_string_literal: true

namespace :tickets do
  desc "Fix customer_ticket data: remove stale CTCs, recalculate consumed_quota and nth_quota"
  task fix_ticket_data: :environment do
    dry_run = ENV["DRY_RUN"] != "false"
    target_user_id = ENV["USER_ID"]

    abort "Usage: rake tickets:fix_ticket_data USER_ID=1077 [DRY_RUN=false]" unless target_user_id

    puts dry_run ? "[DRY RUN]" : "[LIVE]"
    puts "Checking user_id=#{target_user_id}"

    user = User.find(target_user_id)
    ct_ids = CustomerTicket.joins(:customer).where(customers: { user_id: user.id }).pluck(:id)
    puts "Found #{ct_ids.size} customer_tickets"

    stale_deleted = 0
    nth_fixed = 0
    consumed_fixed = 0

    CustomerTicket.where(id: ct_ids).includes(:customer).find_each do |ct|
      ctcs = ct.customer_ticket_consumers.order(:id).to_a
      stale_ctcs = []
      active_ctcs = []

      ctcs.each do |ctc|
        rc = ReservationCustomer.find_by(id: ctc.consumer_id)
        if rc.nil? || rc.canceled? || rc.deleted? || rc.customer_canceled?
          stale_ctcs << ctc
        else
          active_ctcs << ctc
        end
      end

      if stale_ctcs.any?
        stale_ctcs.each do |ctc|
          rc = ReservationCustomer.find_by(id: ctc.consumer_id)
          puts "  [STALE] CT##{ct.id} #{ct.customer.last_name}#{ct.customer.first_name}: " \
               "CTC##{ctc.id} RC##{ctc.consumer_id} state=#{rc&.state || 'MISSING'}"

          unless dry_run
            if rc
              rc_quota = rc.customer_tickets_quota || {}
              if rc_quota.key?(ct.id.to_s) || rc_quota.key?(ct.id)
                rc_quota.delete(ct.id.to_s)
                rc_quota.delete(ct.id)
                rc.update_columns(
                  customer_tickets_quota: rc_quota,
                  booking_amount_cents: nil
                )
              end
            end
            ctc.destroy
          end
          stale_deleted += 1
        end

        new_consumed = active_ctcs.sum { |c| c.ticket_quota_consumed }
        new_state = new_consumed == ct.total_quota ? "completed" : "active"

        if ct.consumed_quota != new_consumed || ct.state != new_state
          puts "  [CONSUMED] CT##{ct.id}: #{ct.consumed_quota} -> #{new_consumed}, state: #{ct.state} -> #{new_state}"
          ct.update_columns(consumed_quota: new_consumed, state: new_state) unless dry_run
          consumed_fixed += 1
        end
      end

      active_ctcs.each_with_index do |ctc, idx|
        correct_nth = idx + 1
        rc = ReservationCustomer.find_by(id: ctc.consumer_id)
        next unless rc

        rc_quota = rc.customer_tickets_quota || {}
        quota_data = rc_quota[ct.id.to_s] || rc_quota[ct.id]
        next unless quota_data

        stored_nth = quota_data["nth_quota"] || quota_data[:nth_quota]
        if stored_nth != correct_nth
          puts "  [NTH] CT##{ct.id} RC##{rc.id} #{ct.customer.last_name}#{ct.customer.first_name}: " \
               "nth #{stored_nth} -> #{correct_nth}"

          unless dry_run
            key = rc_quota.key?(ct.id.to_s) ? ct.id.to_s : ct.id
            rc_quota[key] = quota_data.merge("nth_quota" => correct_nth)
            rc.update_columns(customer_tickets_quota: rc_quota)
          end
          nth_fixed += 1
        end
      end
    end

    puts ""
    puts "Summary:"
    puts "  Stale CTCs #{dry_run ? 'to delete' : 'deleted'}: #{stale_deleted}"
    puts "  consumed_quota #{dry_run ? 'to fix' : 'fixed'}: #{consumed_fixed}"
    puts "  nth_quota #{dry_run ? 'to fix' : 'fixed'}: #{nth_fixed}"
  end
end
