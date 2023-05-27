module Retry
  def with_retry(max_reties: 3)
    count = 0

    begin
      yield
    rescue => e
      count += 1
      sleep(count**2)
      retry if count < max_reties
    end
  end
end
