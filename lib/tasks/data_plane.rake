# frozen_string_literal: true

def data_plane_parse_user_ids(raw)
  raw.to_s.split(/[,\s]+/).filter_map do |part|
    id = part.to_i
    id.positive? ? id : nil
  end.uniq
end

def data_plane_record_users(user_ids, source:, status: "record_only")
  user_ids.each do |user_id|
    unless User.exists?(id: user_id)
      puts "skip user_id=#{user_id} (not found)"
      next
    end

    DataPlaneMigration.record!(
      user_id: user_id,
      status: status,
      source: source,
      metadata: { recorded_at: Time.current.iso8601 }
    )
    puts "recorded user_id=#{user_id}"
  end
end

namespace :data_plane do
  desc "Record data-plane migration for comma-separated user IDs (record-only, no data copy)"
  task :record, [:user_ids] => :environment do |_t, args|
    user_ids = data_plane_parse_user_ids(args[:user_ids])
    abort "Usage: rake data_plane:record[1,2,3]" if user_ids.empty?

    data_plane_record_users(user_ids, source: "rake")
  end

  desc "Record all users as migrated (staging backfill — record only)"
  task record_all: :environment do
    user_ids = User.pluck(:id)
    data_plane_record_users(user_ids, source: "staging_backfill", status: "record_only")
    puts "Recorded #{user_ids.size} users."
  end
end
