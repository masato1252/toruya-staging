# frozen_string_literal: true

json.customer_max_load_capability @customer_max_load_capability || 0
json.errors @errors_with_warnings[:errors]
json.warnings @errors_with_warnings[:warnings]
