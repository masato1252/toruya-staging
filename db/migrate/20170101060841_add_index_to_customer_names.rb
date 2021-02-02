# frozen_string_literal: true

class AddIndexToCustomerNames < ActiveRecord::Migration[5.0]
  # An index can be created concurrently only outside of a transaction.
  disable_ddl_transaction!

  def up
    execute("CREATE INDEX CONCURRENTLY customer_names_on_phonetic_last_name_idx on customers USING gin(phonetic_last_name gin_trgm_ops);")
    execute("CREATE INDEX CONCURRENTLY customer_names_on_phonetic_first_name_idx on customers USING gin(phonetic_first_name gin_trgm_ops);")
    execute("CREATE INDEX CONCURRENTLY customer_names_on_last_name_idx on customers USING gin(last_name gin_trgm_ops);")
    execute("CREATE INDEX CONCURRENTLY customer_names_on_first_name_idx on customers USING gin(first_name gin_trgm_ops);")
  end

  def down
    execute("DROP INDEX customer_names_on_phonetic_last_name_idx on customers;")
    execute("DROP INDEX customer_names_on_phonetic_first_name_idx on customers;")
    execute("DROP INDEX customer_names_on_last_name_idx on customers;")
    execute("DROP INDEX customer_names_on_first_name_idx on customers;")
  end
end
