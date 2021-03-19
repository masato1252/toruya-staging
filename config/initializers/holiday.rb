# frozen_string_literal: true

Holidays.cache_between(Time.now, 3.month.from_now, :jp, :observed)
