# frozen_string_literal: true

module Utils
  def self.bi_weekly_monday(date)
    start_date = Date.new(2023, 1, 1)
    monday = date.beginning_of_week
    weeks_since_start = ((monday - start_date).to_i / 7) + 1
    bi_weekly = weeks_since_start % 2 == 0
    bi_weekly_monday = monday && bi_weekly
  end

  def self.tokyo_current
    Time.current.in_time_zone('Tokyo')
  end

  def self.file_from_url(url)
    response = URI.open(url)
    filename = response.meta['content-disposition'].match(/filename=(["'])?([^'"]+)["']?/)[2] if response.meta['content-disposition']
    content_type = response.meta['content-type']
    tempfile = Tempfile.new([filename, File.extname(filename)])
    tempfile.binmode
    tempfile.write(response.read)
    tempfile.rewind
    tempfile
  end
end
