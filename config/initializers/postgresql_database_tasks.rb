# frozen_string_literal: true

module ActiveRecord
  module Tasks
    class PostgreSQLDatabaseTasks
      def drop
        establish_master_connection
        database = ActiveRecord::Base.connection.current_database
        connection.select_all "select pg_terminate_backend(pg_stat_activity.pid) from pg_stat_activity where datname='#{database}' AND state='idle';"
        connection.drop_database database
      end
    end
  end
end
